# Booksite 纸质书按需印刷下单（Lulu Print API + PayPal）设计文档

> 内部设计文档（私有 `docs/`，不同步到 `peanutbook-docs`）。状态：**P0–P2 已实现**（`web/booksite/printorders/`，2026-10-07），尚未上线。部署步骤见 `docs/new-book-website.md` 第 6 节。
>
> 实现时定下的决策：(1) 必须登录才能下单；只发美国（`PRINT_SHIP_COUNTRIES=US`）。(2) 向读者收的运费 = Lulu `/shipping-options/` 的 `cost_excl_tax` + `shipping_markup`，页面显示的就是实际扣款；Lulu 对运费、履约费另收的税由作者承担（计入毛利）。(3) `/shipping-options/` 不校验 ZIP 与州是否匹配，地址的真正校验发生在点“付款”时的 cost calculation，Lulu 的报错原文会显示给读者。
> 范围：`web/booksite`（单本书、单租户的 Django 站点）。
> API 细节已于 2026-10-07 对照官方资料核对：Lulu 官方 OpenAPI spec（`https://api.lulu.com/api-docs/openapi-specs/openapi_public.yml`，即 `api.lulu.com/docs` 的数据源）和 PayPal 的 Payments v1→v2 迁移指南。

## 1. 背景与目标

现在 booksite 卖纸质书只能靠 `BuyLink` 外链（Amazon / Lulu 书店等）：读者跳到第三方平台，作者拿版税，站点本身不经手钱，也拿不到订单数据。

Lulu 提供 **Print API**：开发者把内文 PDF + 封面 PDF 交给 Lulu，Lulu 按单印刷、直接寄给收件人，再按**印刷批发成本 + 运费 + 税**向 API 账户（作者）收钱。也就是说，书的**零售价由我们自己定、自己收**。

### 目标

1. 读者在书站上直接下单买纸质书：选版本 → 填地址 → 实时报价（书价 + 运费）→ PayPal 付款 → 系统自动向 Lulu 提交印刷任务 → 读者看到订单状态和物流单号。
2. 作者在 `/admin/` 里配置可售版本（尺寸 / 装帧 / 印刷文件 / 零售价），能看到每单毛利，并处理异常订单（重试、退款）。
3. 支付部分沿用 `~/2peanuts.com` 的 PayPal 模式（本地先建 pending 订单 → 跳转 PayPal → 回跳后 capture → 幂等落库），但**不照搬它的实现细节**（原因见 §6.1）。
4. 默认关闭：没配 Lulu / PayPal 凭证的书站跟现在完全一样，零行为变化。这和 `BOOK_PLUGINS`、Google 登录这些“不配就隐藏”的约定一致。

### 非目标（v1 不做）

- 多币种、优惠码、批量 / 团购价、购物车里放多本不同的书（一个站点本来就只有一本书；v1 只支持“一个版本 × 数量”）。
- 电子书销售、章节付费解锁（解锁走的是现有 `Chapter.access_mode`，另议）。
- 退货 / 换货的自动化（Lulu 只对印刷缺陷补印，走人工）。
- 2peanuts.com 的多租户统一收银台。

---

## 2. 现状盘点（可复用的部分）

| 已有 | 位置 | 本功能怎么用 |
| :--- | :--- | :--- |
| Lulu 版式模板 `lulu_7x10` / `lulu_6x9` / `lulu_5.5x8.5` / `lulu_7.5x9.25`（0.5in 安全区） | `build_book.py`, `book_config.py` | `bubble-build` 直接产出符合 Lulu 要求的**内文 PDF** |
| 印刷封面规格 `lulu/paperback`、`lulu/hardcover`（含书脊宽度、出血） | `cover/print_spec.py`, `data/cover_print_config.json` | `gen_fullcover.py` 产出**整张封面 PDF**（封底 + 书脊 + 封面） |
| 单租户 booksite、`CustomUser`、allauth、`BookSettings` 单例、`BuyLink` | `web/booksite/` | 新建一个 `printorders` app 挂在这上面 |
| UI 多语言字符串 | `bookproject/ui_strings.py` | 下单页文案 |
| PayPal 下单 / 回跳 / 取消三段式视图、`PaymentOrder` 模型 | `~/2peanuts.com/accounts/{paypal_service,views,models}.py` | 流程参考，见 §6 |

注意一个已有约束：生产环境下 booksite 会**公开**提供 `MEDIA_ROOT` 下所有文件（`bookproject/urls.py` 里的 `serve_static`）。整本书的内文 PDF **绝不能**放在 `MEDIA_ROOT` 下面（见 §5.2）。

---

## 3. 资金流与总体流程

```
读者 ──(零售价 + 运费)──▶ PayPal ──▶ 作者 PayPal 账户
                                         │
作者 Lulu API 账户（绑定的信用卡）──(印刷成本 + 运费 + 税 + 履约费)──▶ Lulu ──印刷/寄送──▶ 读者
```

站点在两边都只是 API 调用方：钱先进作者的 PayPal，Lulu 再从作者在 Lulu 绑定的支付方式扣印刷费。**毛利 = 读者实付 − Lulu 实扣 − PayPal 手续费**。

### 下单时序

```
Reader            Booksite                         PayPal                 Lulu
  │  选版本/数量/地址 │                                 │                      │
  │ ───────────────▶ │ POST /print-job-cost-calculations ──────────────────▶ │
  │                  │ ◀──────────── 印刷成本、各运费档、税 ──────────────────── │
  │ ◀── 报价(书价+运费)│ 存 PrintOrder(status=QUOTED, 报价快照)                    │
  │  点 PayPal 付款   │                                 │                      │
  │ ───────────────▶ │ POST /v2/checkout/orders ──────▶ │                      │
  │ ◀──── 跳转 approve│ status=PAYMENT_PENDING          │                      │
  │ ─────────── 在 PayPal 确认 ───────────────────────▶ │                      │
  │ ◀──────────── 回跳 return_url ───────────────────── │                      │
  │ ───────────────▶ │ POST /v2/checkout/orders/{id}/capture ▶ │               │
  │                  │ status=PAID（事务内，幂等）         │                      │
  │                  │ POST /print-jobs/ ─────────────────────────────────────▶ │
  │                  │ status=SUBMITTED, lulu_print_job_id                      │
  │ ◀── 订单详情页    │                                                          │
  │                  │ ◀──── webhook PRINT_JOB_STATUS_CHANGED / 定时轮询 ─────── │
  │                  │ IN_PRODUCTION → SHIPPED（物流单号）→ 邮件通知读者          │
```

**关键顺序：先收钱，再向 Lulu 提交。** 反过来做的话，读者放弃付款时作者已经被 Lulu 扣了钱。提交失败的情况（已收款但 Lulu 拒单）走 §8 的异常处理，在作者确认的前提下退款。

---

## 4. 数据模型（新 app：`printorders`）

### 4.1 `PrintEdition`：一个可售的纸质版本（admin 维护）

| 字段 | 说明 |
| :--- | :--- |
| `language` | 跟 `BuyLink.language` 一样的选项。中文版和英文版是两个 edition |
| `name` | 显示名，如 “平装 7×10 彩色” |
| `pod_package_id` | Lulu 产品编码，**用新的点分格式**：`[Trim].[Ink].[Quality].[Binding].[Paper].[Finish]`，如 `0700X1000.FC.STD.PB.080CW444.GXX`（7×10 / 彩色 / 标准 / 胶装 / 80# 铜版白 / 光膜）、`0600X0900.BW.STD.PB.060UW444.MXX`（6×9 黑白 / 60# 白胶版纸 / 哑膜）。旧的 27 位无点格式从 2026-03-31 起只是兼容支持，**2027-02-01 停止支持**，所以存储和校验都只接受点分格式。admin 里提供一个组合器（尺寸默认取 `peanut.config` 的 template），也可以直接粘贴 developers.lulu.com/price-calculator 生成的编码 |
| `interior_pdf` / `cover_pdf` | 印刷文件，存在**私有存储**（§5.2） |
| `page_count` | 上传时用 PDF 解析自动填，只读；Lulu 内文校验返回的 `page_count` 会再核对一次 |
| `lulu_printable_id` | 第一次成功印刷后 Lulu 返回的 `line_items[].printable_id`。之后的订单直接引用它，不用再提交 `printable_normalization`，Lulu 也不用重新下载、重新规范化文件（官方说明这就是用于 re-order 的）。文件一换就清空 |
| `retail_price` / `currency` | 书的零售价（v1 只支持 `USD`） |
| `shipping_markup` | 运费加价（默认 0 = 运费按 Lulu 成本原价转嫁） |
| `validation_status` / `validation_message` / `validated_at` | Lulu 文件校验结果（§5.3）。只有 `VALIDATED` 的版本才能上架 |
| `unit_cost_snapshot` | 最近一次查到的单本印刷成本，admin 列表里用来显示毛利 |
| `is_active`、`order` | 上架开关与排序 |
| `max_quantity` | 单笔订单数量上限（默认 10，防止误下大单） |

文件或 `pod_package_id` 一变，`validation_status` 就自动回到 `PENDING`，必须重新校验才能继续卖。

### 4.2 `PrintOrder`：一笔订单

| 字段 | 说明 |
| :--- | :--- |
| `id` | UUID（读者订单页 URL 用它，不暴露自增 id） |
| `user` | FK `CustomUser`（v1 要求登录，见 §11 Q1） |
| `edition`、`quantity` | |
| `shipping_address` | JSON：`name, street1, street2, city, state_code, postcode, country_code, phone_number`。Lulu 的约束：**`street1` / `street2` / `city` ≤ 30 字符，`name` ≤ 35**；电话必填，需匹配 `^\+?[\d\s\-.\/()]{8,20}$`；US / CA / AU / CN / HK / TW / JP 等国家和地区必须填 `state_code`；巴西、智利、墨西哥另需 `recipient_tax_id`（v1 白名单不包含这三个国家）。表单要按这些规则做前端和后端校验，不然要等到下单时才被 Lulu 拒绝。Lulu 可能返回 `suggested_address` / `warnings`（比如自动改写街道名），报价页要把这些展示给读者确认 |
| `contact_email` | 默认取用户邮箱 |
| `shipping_level` | `MAIL` / `PRIORITY_MAIL` / `GROUND_HD` / `GROUND_BUS` / `GROUND` / `EXPEDITED` / `EXPRESS`。可选档位和价格以 `/shipping-options/` 对这个地址的返回结果为准，不在前端写死 |
| `quote` | JSON 快照：Lulu 报价原文、`book_subtotal`、`shipping_charged`、`total_charged`、`lulu_cost_total`、`quoted_at` |
| `amount_charged` / `currency` | 实际向读者收取的金额（服务端计算，**绝不信任前端**） |
| `paypal_order_id` / `paypal_capture_id` / `paypal_payer_email` | |
| `lulu_print_job_id` / `lulu_status` / `lulu_status_message` | |
| `tracking` | JSON：承运商、单号、跟踪 URL 列表（Lulu 可能分包裹） |
| `status` | 见 §4.3 |
| `admin_note`、`created_at`、`updated_at`、`paid_at`、`submitted_at`、`shipped_at` | |

`PrintOrderEvent(order, kind, payload, created_at)`：只追加的审计日志，记录每次 PayPal 和 Lulu 的请求/回调。排查“钱扣了但没印”这类问题全靠它。

### 4.3 订单状态机

```
QUOTED ──▶ PAYMENT_PENDING ──▶ PAID ──▶ SUBMITTED ──▶ IN_PRODUCTION ──▶ SHIPPED
   │              │    │          ▲  │          │
   └─(过期)       │    └▶ PAYMENT_HELD (capture PENDING；DENIED → CANCELLED)
                  └─▶ CANCELLED      │          └─▶ LULU_REJECTED ─┐
                                  └─▶ SUBMIT_FAILED ────────────┴─▶ NEEDS_ATTENTION ─▶ REFUNDED
                                                                                    └─▶ (重试) SUBMITTED
```

- 所有状态迁移都集中在 `printorders/services.py` 的函数里，用 `select_for_update()` + 前置状态检查保证幂等。这样 PayPal 回跳和 webhook 同时到达、或者用户重复刷新，都只会 capture 一次、提交一次。
- Lulu 侧状态原样存在 `lulu_status` 里，再映射到我们的粗粒度 `status`。官方的状态迁移图：
  `CREATED → UNPAID / REJECTED / CANCELED / PRODUCTION_READY`；`UNPAID → PAYMENT_IN_PROGRESS / CANCELED / PRODUCTION_DELAYED`；`PAYMENT_IN_PROGRESS → UNPAID / PRODUCTION_DELAYED`；`PRODUCTION_DELAYED → PRODUCTION_READY / CANCELED`；`PRODUCTION_READY → IN_PRODUCTION / PRODUCTION_DELAYED`；`IN_PRODUCTION → SHIPPED / ERROR`；之后还有 `DELIVERED`（只有 USPS / FedEx / UPS 会回传，不保证一定出现）。
  映射规则：`CREATED / PRODUCTION_*` → `SUBMITTED`，`IN_PRODUCTION` → `IN_PRODUCTION`，`SHIPPED / DELIVERED` → `SHIPPED`，`REJECTED / ERROR / CANCELED`（Lulu 主动取消）→ `NEEDS_ATTENTION`。
- **Lulu 怎么收作者的钱**（官方原文的意思）：print job 建好后停在 `UNPAID`，要么作者去 developer portal 手动付款，要么**在账户里绑定信用卡**，这样 job 会自动进入 `PRODUCTION_DELAYED`，真正送去生产时才扣卡。所以**上线前提是作者在 Lulu 账户里绑好信用卡**（P0 的 checklist 里要写明）。订单长时间停在 `UNPAID` 就说明没绑卡或者扣卡失败，映射到 `NEEDS_ATTENTION` 并通知作者。这是作者那边的问题，不是读者的。
- **`production_delay`**：可以设 60 到 2880 分钟。我们默认设 **120 分钟**。这段时间里 job 停在 `PRODUCTION_DELAYED`，可以通过 `PUT /print-jobs/{id}/status/ {"name":"CANCELED"}` 取消，正好用作“读者付款后马上要求取消 / 作者发现地址有问题”的窗口。到了 `PRODUCTION_READY` 之后就取消不了了。

---

## 5. Lulu 集成

### 5.1 客户端模块 `printorders/lulu.py`

一个薄封装，用 `requests`，不引第三方 SDK：

| 函数 | Lulu 端点（已对照官方 spec） |
| :--- | :--- |
| `_token()` | `POST /auth/realms/glasstree/protocol/openid-connect/token`，form body `grant_type=client_credentials`，头 `Authorization: Basic base64(key:secret)`。返回的 `expires_in` 是 3600 秒，按这个值缓存，提前 60 秒刷新 |
| `shipping_options(edition, qty, address)` | `POST /shipping-options/`：body 是 `line_items[{page_count, pod_package_id, quantity}]` 加 `shipping_address{country, state, ...}`，只有 `country` 必填，但官方说要带 `state` 才能拿到准确运费。返回每个 `level` 的 `cost_excl_tax`，以及 `min/max_delivery_date` |
| `calculate_cost(edition, qty, address, level)` | `POST /print-job-cost-calculations/`：body 是 `line_items` + 完整的 `shipping_address`（必填 `street1, city, country_code, postcode, phone_number`）+ `shipping_option`。返回 `line_item_costs[]`、`shipping_cost`、`fees[]`（实测示例里有 `HANDLING_FEE` 和 `FULFILLMENT_FEE`）、`total_tax`、`total_cost_incl_tax`，金额都是 decimal 字符串，币种默认 USD |
| `validate_interior(url, pod)` | `POST /validate-interior/` `{source_url, pod_package_id}`，然后轮询 `GET /validate-interior/{id}/`。终态是 `VALIDATED` / `NORMALIZED`（传了 pod 时）/ `ERROR`（`errors[]`）。返回里还有 `page_count` 和 `valid_pod_package_ids` |
| `validate_cover(url, pod, page_count)` | `POST /validate-cover/` `{source_url, pod_package_id, interior_page_count}`，然后轮询 `GET /validate-cover/{id}/`。终态是 `NORMALIZED` / `ERROR` |
| `cover_dimensions(pod, page_count)` | `POST /cover-dimensions/` `{pod_package_id, interior_page_count, unit: "inch"}` → `{width, height}`。和 `cover/print_spec.py` 算出的尺寸互相校验 |
| `create_print_job(order)` | `POST /print-jobs/`：`{contact_email, external_id: order.id, shipping_level, production_delay: 120, shipping_address, line_items: [{external_id, title, quantity, printable_normalization: {pod_package_id, interior: {source_url}, cover: {source_url}}}]}`。如果 edition 已有 `lulu_printable_id`，就把整个 `printable_normalization` 换成 `printable_id` |
| `get_print_job(job_id)` / `get_status(job_id)` | `GET /print-jobs/{id}/`、`GET /print-jobs/{id}/status/`。物流信息在 `line_item_statuses[].messages.{tracking_id, tracking_urls[], carrier_name}` |
| `list_jobs_by_external_id(order_id)` | `GET /print-jobs/?external_id=...`（列表端点支持按字段过滤，实现时确认参数名），用于重试前查重 |
| `cancel_print_job(job_id)` | `PUT /print-jobs/{id}/status/` `{"name": "CANCELED"}`，只在 `UNPAID` / `PRODUCTION_DELAYED` 阶段有效 |
| `get_actual_costs(job_id)` | `GET /print-jobs/{id}/costs/`：记录 Lulu 实际收的钱，用来算真实毛利 |

- 环境：`LULU_SANDBOX=true` 时用 `api.sandbox.lulu.com`（沙箱下单不会真的印刷，扣的是测试卡），否则用 `api.lulu.com`。
- 所有调用设超时（连接 5s / 读取 30s），失败抛 `LuluError`，带上 HTTP 状态码和响应体，写进 `PrintOrderEvent`。
- 沙箱需要在 `developers.sandbox.lulu.com` **单独注册一个账户**（key/secret 和正式环境不通用）。沙箱的 job 永远不会真的生产，付款用测试信用卡。
- Lulu spec 里没有写明速率限制，客户端遇到 429 时按 `Retry-After` 退避就行。

### 5.2 印刷文件的存储与供 Lulu 拉取

Lulu 是**从 URL 拉文件**，不接受直接上传。所以：

- `PrintEdition` 的文件用一个独立的 `FileSystemStorage`，根目录 `PRINT_FILES_ROOT`（默认 `BASE_DIR/private_print_files/`，Docker 下挂到 `data/` 里），**不在 `MEDIA_ROOT` 下，也没有任何公开路由**。
- 新增一个视图 `GET /print-files/<signed-token>/`。token 用 `django.core.signing.TimestampSigner` 签发，载荷是 `(edition_id, kind, file_sha256)`，有效期 7 天。只在调用 validate 和 create_print_job 时生成，发给 Lulu。文件一旦被替换，sha 变化，旧链接自动失效。
- 这样整本书的 PDF 不会出现在任何可猜测的 URL 上，和章节付费墙的保护强度保持一致。Lulu 官方也支持在 URL 里带 basic auth（`https://user:pass@host/...`），但用签名 token 就够了，不用再多维护一套密码。
- 有了 `lulu_printable_id` 之后，日常订单就不再需要 Lulu 下载文件，签名 URL 只在上架校验和第一单时用到，暴露窗口很小。
- 文件来源：作者在 admin 上传 `bubble-build` 产出的内文 PDF 和 `gen_fullcover.py --provider lulu/paperback` 产出的封面 PDF。v2 可以考虑加一个“从 `BOOK_ROOT` 的构建产物导入”按钮（Docker 部署时 book 项目本来就挂载进容器了）。

### 5.3 上架前校验（关键：别让读者的订单撞上文件问题）

admin 的 `PrintEdition` 上有一个 **“Validate with Lulu”** action：

1. 用 `pypdf` 读页数，确认页面尺寸和 `pod_package_id` 的开本一致（本地先挡一道）。
2. 调用 `validate-interior`（带 pod，跑完整的 normalization 校验），确认返回的 `valid_pod_package_ids` 里包含我们的 pod；然后调用 `validate-cover`（带上页数）。官方列出的常见失败原因：页面尺寸不一致、字体没嵌入、图片损坏、不足 2 页。
3. 调用 `cover-dimensions`，把结果和封面 PDF 的实际尺寸比对，误差超过 1/16in 就报错。这种情况一般是页数变了但封面书脊没有重新生成。
4. 用一个美国地址做一次 cost calculation，把单本成本写进 `unit_cost_snapshot`，同时在 admin 里提示“零售价 − 单本成本 = 毛利（未扣运费 / PayPal 手续费）”。零售价低于成本时禁止上架。

全部通过才设为 `VALIDATED`。

### 5.4 状态同步

- **Webhook（首选）**：`POST /print-orders/lulu/webhook/`，订阅 `PRINT_JOB_STATUS_CHANGED`（目前 Lulu 唯一的 topic）。payload 是 `{topic, data}`，`data` 和 `GET /print-jobs/{id}/` 返回的一样。
  - 验签：头 `Lulu-HMAC-SHA256` = HMAC-SHA256(key = API secret 的 UTF-8 编码, msg = **原始请求体**)。官方特别提醒不要先解析 JSON 再序列化，否则签名对不上。所以要用 `request.body` 计算，再和头里的值用 `hmac.compare_digest` 比较。校验不过返回 401。处理逻辑幂等。
  - Lulu 投递失败会重试 5 次。**连续 5 次失败后 webhook 会被自动停用**（`is_active=false`），需要调用 `PUT /webhooks/{id}/` 重新启用。所以 `sync_print_orders` 每次运行时顺便检查一下 webhook 状态，被停用就自动重新启用，并通知作者。
  - 提供 `python manage.py lulu_webhook_register`（调用 `POST /webhooks/`；每个 URL 只能注册一个），用当前站点域名注册，并调用 `POST /webhooks/{id}/test-submission/PRINT_JOB_STATUS_CHANGED/` 做一次连通性测试。单租户的每个书站各注册各的。
- **轮询（兜底）**：`python manage.py sync_print_orders`，把所有 `SUBMITTED / IN_PRODUCTION` 的订单拉一遍状态。Docker 部署可以在 compose 里加一个每小时跑的 cron sidecar。不想配 webhook 的书站只靠轮询也能用。

---

## 6. PayPal 集成

### 6.1 参考 2peanuts，但不照搬的地方

2peanuts 的流程骨架（先建 pending 订单 → 跳转 approve → 回跳 execute → 失败/取消改状态）是对的，直接沿用。下面三处要改：

1. **API 版本**：2peanuts 用的是 `paypalrestsdk` + v1 `/payments`（intent=sale）。PayPal 官方迁移指南的原话是 “The Payments v1 API is deprecated and will be removed”。指南里没有给出具体日期；有搜索结果提到 2027 年 1 月下线，但我没在官方页面上找到印证。不管哪天下线，**2peanuts 本身也需要迁移**。booksite 直接用 **Orders v2**（`POST /v2/checkout/orders` → approve → `POST /v2/checkout/orders/{id}/capture`），用 `requests` 调用，不引 SDK。
2. **沙箱短路是安全漏洞，不能照搬**：2peanuts 的 `execute_paypal_payment` 在“未配置凭证 **或** `payment_id` 以 `PAYID-SANDBOX-` 开头”时直接把订单标记为已完成。`payment_id` 来自回跳 URL 的 query 参数，用户可以随便改，所以任何人都能不付钱完成订单。booksite 不做这种短路：没配置就直接不显示购买入口；测试一律走真正的 PayPal sandbox。**建议 2peanuts 那边也修掉。**
3. **金额以服务端为准**：capture 之后核对 PayPal 返回的 `amount.value` 和 `currency_code` 是否等于 `order.amount_charged`，不一致就进 `NEEDS_ATTENTION`，不向 Lulu 提交。

### 6.2 交互形式

v1 用**跳转式**（和 2peanuts 一样，服务端渲染、零前端依赖）：

- `POST /<lang>/print/order/<uuid>/pay/` → 创建 PayPal order，然后 302 到返回的 `links[rel=payer-action]`（老写法是 `approve`，两个都兼容）。请求体：
  ```json
  {
    "intent": "CAPTURE",
    "purchase_units": [{
      "custom_id": "<order.id>",
      "invoice_id": "<order.id>",
      "amount": {"currency_code": "USD", "value": "34.90",
                 "breakdown": {"item_total": {...}, "shipping": {...}}},
      "items": [{"name": "<书名> (Paperback)", "quantity": "1", "unit_amount": {...}, "category": "PHYSICAL_GOODS"}],
      "shipping": {"name": {"full_name": "..."}, "address": {"address_line_1": "...", "admin_area_2": "<city>", "admin_area_1": "<state>", "postal_code": "...", "country_code": "US"}}
    }],
    "payment_source": {"paypal": {"experience_context": {
      "brand_name": "<BOOK_TITLE>", "user_action": "PAY_NOW",
      "shipping_preference": "SET_PROVIDED_ADDRESS",
      "return_url": ".../paypal/return/", "cancel_url": ".../paypal/cancel/"
    }}}
  }
  ```
  - v2 把 v1 的 `redirect_urls` / `application_context` 合并进了 `payment_source.paypal.experience_context`，v1 的 `user_action: "commit"` 对应 v2 的 `PAY_NOW`。
  - `SET_PROVIDED_ADDRESS`：把读者在我们页面填的地址传给 PayPal 并锁定，避免 PayPal 侧改了地址、和寄给 Lulu 的地址不一致。
  - 请求头带 `PayPal-Request-Id: create-<order.id>-<quote version>`，保证同一个报价重复提交不会生成两个 PayPal order。`invoice_id` 是 PayPal 侧的第二道防重。
- `GET /<lang>/print/order/<uuid>/paypal/return/?token=...` → `POST /v2/checkout/orders/{id}/capture`（请求头带 `PayPal-Request-Id: capture-<order.id>`），然后**看 capture 的状态**（`purchase_units[0].payments.captures[0].status`）：
  - `COMPLETED` → `PAID`，接着提交 Lulu。
  - `PENDING`（eCheck、风控审核等）→ 留在新状态 `PAYMENT_HELD`，**不提交 Lulu**，等 webhook `PAYMENT.CAPTURE.COMPLETED` 到了再继续；如果收到 `PAYMENT.CAPTURE.DENIED` 就取消订单。
  - 手续费从 `seller_receivable_breakdown.paypal_fee` 读，写进订单，admin 的毛利就是精确值。
- `GET /<lang>/print/order/<uuid>/paypal/cancel/` → 订单改为 `CANCELLED`。

v2 可以换成 PayPal JS SDK 按钮（页内弹窗，转化率更高），后端的 create / capture 接口不用改。

### 6.3 Webhook 兜底

`POST /print-orders/paypal/webhook/` 处理 `PAYMENT.CAPTURE.COMPLETED` / `PAYMENT.CAPTURE.PENDING` / `PAYMENT.CAPTURE.DENIED` / `PAYMENT.CAPTURE.REFUNDED`，用 `PAYPAL_WEBHOOK_ID` 调 `POST /v1/notifications/verify-webhook-signature` 验签（这个验签端点 v2 集成也在用，没有被废弃）。它覆盖的场景是：读者付完款后关了浏览器、没回跳，订单停在 `PAYMENT_PENDING`。webhook 收到后走同一个幂等的 `mark_paid_and_submit()`。

另外，`sync_print_orders` 也会对超过 15 分钟的 `PAYMENT_PENDING` 订单查一次 PayPal order 状态，作为双保险。

---

## 7. 定价与报价

读者看到的价格：

```
书价小计   = edition.retail_price × quantity
运费       = Lulu shipping_cost.total_cost_incl_tax + edition.shipping_markup
应付合计   = 书价小计 + 运费

作者成本   = Lulu total_cost_incl_tax（印刷 + 运费 + fees[HANDLING_FEE / FULFILLMENT_FEE] + 税）
毛利       = 应付合计 − 作者成本 − PayPal fee
```

- 注意 Lulu 的报价里有**按单收的 `fees`**（官方示例：`FULFILLMENT_FEE` $0.75，以及一项 `HANDLING_FEE`），而且对印刷、运费、各项 fee 都会按收货地址计税（cost calculation 必须带地址，就是为了算 sales tax / VAT）。v1 把这些 fee 算进作者成本、不向读者单列。admin 毛利预览要用一个真实地址的完整报价来算，不能只看单本印刷价。

- 报价**只在服务端算**：地址或档位一变，前端用 fetch 请求 `POST /<lang>/print/quote/`，服务端调 Lulu、存 `QUOTED` 快照、返回金额。PayPal 下单时用的是快照里的金额。
- 报价有效期 30 分钟。过期后点付款会先自动重新报价，金额有变化就让读者再确认一次。
- **Lulu 的印刷成本和印刷环节的税是作者的成本**，不单独向读者列出。书价本身就是含利润的零售价。
- admin 订单列表直接显示每单的“实收 / Lulu 成本 / PayPal 手续费（capture 回执里有）/ 毛利”。
- 可配送国家：v1 用 `PRINT_SHIP_COUNTRIES` 白名单（默认 `US`），避免一开始就碰到国际运费、关税、VAT 等复杂情况。
- 币种：Lulu 的报价支持 AUD / CAD / EUR / GBP / USD，PayPal 也都支持，但 v1 只做 USD。以后开放其他币种时，读者付款币种要和 Lulu 报价币种一致，避免汇率差额。

税务这块需要作者自己确认（§11 Q3）：作为零售卖家，向某些美国州的读者卖实体书可能要收销售税。v1 先假设作者体量低于各州的 economic nexus 门槛，不收；页面上加一句“价格不含可能的进口关税”。

---

## 8. 异常处理

| 场景 | 处理 |
| :--- | :--- |
| 读者放弃 / 取消 PayPal | `CANCELLED`，什么都不提交 |
| capture 失败（余额不足、风控） | 留在 `PAYMENT_PENDING`，页面提示重新付款 |
| capture 成功，Lulu `create_print_job` 网络错误或 5xx | `SUBMIT_FAILED`，自动重试 3 次（指数退避，在 `sync_print_orders` 里跑）。用 `external_id=order.id` 先查有没有已建的 job，防止重复印刷 |
| Lulu 返回 4xx（地址不合法等） | `NEEDS_ATTENTION`，邮件通知作者 |
| Lulu `REJECTED`（文件问题，按 §5.3 本不该出现） | `NEEDS_ATTENTION`，邮件通知作者 |
| Lulu `UNPAID`（作者的卡扣款失败） | `NEEDS_ATTENTION`，邮件通知作者去 Lulu 后台更新支付方式，之后在 admin 点“重试” |
| 读者付款后马上要求取消 | 在 `production_delay`（120 分钟）窗口内，admin 点 “Cancel & refund”：先 `PUT /print-jobs/{id}/status/ CANCELED`，成功后再退款。过了窗口就只能按“不退款 / 收到书后协商”处理 |
| 作者决定不印 | admin action **“Refund via PayPal”** → `POST /v2/payments/captures/{id}/refund`（请求头带 `PayPal-Request-Id`；退款原因写 `note_to_payer`）→ `REFUNDED`，并在还能取消时取消 Lulu job |

admin 里的 `NEEDS_ATTENTION` 订单置顶、标红。两个关键 action 是 “Retry Lulu submission” 和 “Refund”，都要二次确认。

---

## 9. 读者侧页面与 admin

### 读者侧（新 URL 要放在 `chapters.urls` 的 `<str:lang>/<slug:slug>/` 兜底路由**之前**，原因和 praise / events 一样）

- `/<lang>/print/`：可售版本列表（封面图、开本、页数、价格）。首页 hero 的购买区和 `BuyLink` 并列显示一个 “Order a printed copy” 按钮。只有存在 `is_active & VALIDATED` 的版本，且 Lulu 和 PayPal 都已配置时才显示（context processor 里加 `print_ordering_enabled`）。
- `/<lang>/print/<edition_id>/checkout/`：数量、地址表单（国家下拉受白名单限制）、运费档位单选、实时报价、PayPal 按钮。需要登录。
- `/<lang>/print/orders/`、`/<lang>/print/order/<uuid>/`：我的订单 / 订单详情（状态进度条、物流链接）。只有订单所有者和 staff 能看。
- 文案全部放进 `ui_strings.py`，覆盖所有语言。

### admin

- `PrintEdition`：上传文件、组合 `pod_package_id`、validate action、毛利预览。
- `PrintOrder`：只读为主，按状态过滤，提供 retry / refund / sync now 三个 action，inline 显示 `PrintOrderEvent` 时间线。地址字段可以编辑（仅限 `NEEDS_ATTENTION` 状态）。

### 邮件

booksite 目前没有配置 SMTP，需要新增 `EMAIL_*` 环境变量。没配的话退化为 console backend，并在 admin 首页提示。需要的邮件：

- 读者：付款成功、已发货（附物流单号）。
- 作者（`BOOKSITE_ADMIN_EMAIL`）：新订单、`NEEDS_ATTENTION`。

---

## 10. 配置、部署、安全、测试

### `.env` 新增变量

```ini
# 全部留空 = 功能关闭，站点行为与现在完全相同
LULU_CLIENT_KEY=
LULU_CLIENT_SECRET=
LULU_SANDBOX=true
LULU_WEBHOOK_ENABLED=false
PAYPAL_CLIENT_ID=
PAYPAL_CLIENT_SECRET=
PAYPAL_MODE=sandbox            # sandbox | live
PAYPAL_WEBHOOK_ID=
LULU_PRODUCTION_DELAY_MINUTES=120   # 60..2880
PRINT_SHIP_COUNTRIES=US
PRINT_FILES_ROOT=              # 默认 BASE_DIR/private_print_files
EMAIL_HOST= / EMAIL_PORT= / EMAIL_HOST_USER= / EMAIL_HOST_PASSWORD= / DEFAULT_FROM_EMAIL=
```

同步更新 `.env.example`、`scripts/new_book_docker_site.sh` 生成的 `.env` 模板、`docs/new-book-website.md`（新增“开通纸书销售”一节）。新依赖只有 `requests` 和 `pypdf`。

### 安全清单

- 所有金额由服务端从 `PrintEdition` 和报价快照计算，前端提交的金额一律忽略。
- PayPal 和 Lulu 的 webhook 都要验签。验签失败返回 401，并记录日志。
- capture / submit 用行锁 + 前置状态检查保证幂等。PayPal `invoice_id` 和 Lulu `external_id` 都用 `order.id`，作为外部防重的第二层。
- 印刷 PDF 只放在私有存储，通过限时签名 URL 提供（§5.2）。
- 订单页校验所有权。UUID 只是不可猜，不能替代授权检查。
- 地址属于 PII：admin 加一个“清理 180 天前已发货订单的电话和街道地址”的管理命令（可选）。
- 生产环境启动时检查：`PAYPAL_MODE=live` 但 `LULU_SANDBOX=true`（或反过来）就拒绝启用该功能。不然会出现“真收钱、假印刷”。

### 测试

- 单元测试：用 `responses` / `unittest.mock` 模拟 Lulu 和 PayPal 的 HTTP。覆盖状态机的每一条边、重复回跳、webhook 和回跳竞争、金额不一致、HMAC 错误。
- 集成：在 Lulu sandbox + PayPal sandbox 上，用一本真书（比如 `~/mmb`）跑通“上传 → 校验 → 下单 → 付款 → 提交 → 用 sandbox 手动推进状态 → webhook → 已发货邮件”。
- 上线前用 live 环境给自己下一单真单，验证实物、成本和毛利。

---

## 11. 待决问题（需要你拍板）

1. **是否必须登录才能下单？** 建议 v1 必须登录：现有用户体系现成，订单历史好做，也和章节解锁统一。代价是转化率低一点。v2 可以加 guest checkout，用邮件里的 magic link 查看订单。
2. **哪些开本 / 装帧先上？** 建议先上 `lulu_7x10` 平装（和现有默认 template 一致），精装（`lulu/hardcover` 封面规格已有）放到 v1.1。
3. **销售税 / 发票**：作者以什么身份卖（个人 / LLC），是否需要收州销售税？这决定了 §7 要不要接入 tax 计算。
4. **配送范围**：只发美国，还是也开放中国大陆 / 港台？中文版的读者很可能在海外华人区，但国际运费贵、时效长，需要先用 sandbox 报价看看实际价格。
5. **PayPal 账户**：用 2peanuts 那个 PayPal 商户（同一个 Client ID，换一个 app），还是每本书 / 每个作者单独一个？单租户设计天然支持每个站点不同，建议在 `.env` 里按站点配置。
6. **Lulu 的 contact_email / 退货地址**：用作者的邮箱还是统一的出版社邮箱？

---

## 12. 分阶段计划

| 阶段 | 内容 | 验收 |
| :--- | :--- | :--- |
| **P0 印刷文件就绪** | 前置条件：注册 Lulu 正式账户和沙箱账户，**在正式账户里绑好信用卡**（否则每个 job 都会卡在 `UNPAID`）。然后做 `printorders` app、`PrintEdition`、私有存储 + 签名 URL、`lulu.py`（token / validate / cover-dimensions / cost）、admin validate action | 在 sandbox 里校验通过一本真书，admin 显示单本成本和毛利 |
| **P1 下单闭环** | `PrintOrder` + 状态机、报价接口、checkout 页、PayPal Orders v2 跳转式 create / capture、`create_print_job`、订单详情页 | sandbox 下单后 Lulu sandbox 出现 print job |
| **P2 运维** | Lulu / PayPal webhook、`sync_print_orders` 轮询与重试、refund / retry action、`PrintOrderEvent` 时间线、邮件通知 | 模拟各种异常都能在 admin 里处理完 |
| **P3 上线** | live 凭证、自购一单、文档（`docs/new-book-website.md`，如果是面向用户的功能也更新 `~/peanutbook-docs`） | 实物到手，毛利和预期一致 |
| 之后 | 精装、PayPal JS 按钮、guest checkout、多币种、从 `BOOK_ROOT` 一键导入构建产物 | |

---

## 参考资料（2026-10-07 核对）

- Lulu Print API 文档：https://api.lulu.com/docs/ （OpenAPI 源文件：https://api.lulu.com/api-docs/openapi-specs/openapi_public.yml）
- Lulu 价格计算器 / pod_package_id 生成：https://developers.lulu.com/price-calculator
- Lulu 产品规格表：https://assets.lulu.com/media/specs/lulu-print-api-spec-sheet.xlsx
- Lulu 制书指南（PDF 规格、书脊）：https://assets.lulu.com/media/guides/en/lulu-book-creation-guide.pdf
- PayPal Orders v2：https://developer.paypal.com/docs/api/orders/v2/
- PayPal Payments v1→v2 迁移指南：https://developer.paypal.com/api/rest/integration/payments-api/v1-v2-migration

