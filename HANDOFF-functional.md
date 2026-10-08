# HANDOFF — tidydr 功能性扩展（Functional Round）

> 这是给**执行方 AI** 的工作交接单，接在稳健性轮（`HANDOFF-robustness.md`）之后。
> 文档里每条"事实"都已实测；未经验证的结论一律标注 **UNVERIFIED**。
> 先读第 1 节（起点）与第 2 节（前置条件）——**前置条件不满足时不要开工**。

---

## 0. 一句话任务

在稳健性轮打下的基础上做功能扩展：让 `nk()` 支持可插拔聚类、新增多方法批量比较的
`dr_compare()`、给 `DrResult` 加扩展槽、把文档宣称的方法变成有测试覆盖的事实、
补细粒度轮廓导出。产出 = 源码 + 测试 + 文档，最终 `R CMD check` 保持 `0/0/0`。

---

## 1. 起点与环境

| 项 | 值 |
| --- | --- |
| 仓库绝对路径 | `/home/wang/data/source/tidydr` |
| 最后提交 | `065bcc4`（"Record operator decisions in robustness handoff"） |
| **稳健性轮改动** | **全部未提交，躺在工作树里**（见第 2 节） |
| `DESCRIPTION` 的 Version | 已是 `0.0.6.001` |
| R 版本 | 4.6.1 (2026-06-24) |
| 测试基线 | **120 断言 / 5 个测试文件 / 全绿**（我实测确认；`9+22+29+24+36`） |
| `R CMD check` | `0 errors / 0 warnings / 0 notes`（按 `ROBUSTNESS-REVIEW.md` 记载） |

**已装（可本地验证）**：`devtools 2.5.2`、`testthat 3.3.2`、`roxygen2 8.1.0`、
`cluster 2.1.8.2`、`MASS 7.3.66`、`Rtsne 0.17`、`uwot 0.2.5`、`ape 5.8.1`、`yaml 2.3.12`。

**未装**：`ecodist`、`ade4`、`labdsv`、`smacof`、`vegan`、`covr`。

### 稳健性轮已经做完的事（**不要重复做**）

`HANDOFF-robustness.md` 的 U1–U5 已在工作树落地，并有两轮独立审核
（见 `ROBUSTNESS-REVIEW.md`，含下游 `ggsc` / `enrichplot` 的 A/B 兼容性验证）：

- `dr()` 输入校验（`validate_dr_data()` / `check_finite_dr_data()`）
- `nk()` 的 `data` / `k` 校验（`validate_nk_data()` / `validate_nk_k()`；`k=1` 报错；
  **`dist` 对象显式支持**，用 `attr(data, "Size")` 取 n）
- `fortify()` 的 metadata 类型分派（matrix 走 data.frame 路径；list 明确 warning 并忽略）
- **`dr_extract.matrix` 兜底已存在**：`stats::cmdscale` 与"返回裸矩阵的包装函数"现在都能用
  （`dr(as.dist(dist(iris[,1:4])), stats::cmdscale)` → 150x2 ✓）
- `.github/workflows/R-CMD-check.yaml`
- `.Rbuildignore` 已含 `^\.github$`、`^ROBUSTNESS-.*\.md$`、`^\.workbuddy-ai$`

---

## 2. 前置条件（不满足就停下并询问）

**稳健性轮的 15 个文件改动 + 新增文件目前全部未提交。** 功能轮不能建立在一个浮动的工作树上：

- 若操作方**尚未**提交稳健性轮 → 功能轮从工作树起改，任何回滚/对比都会把两轮混在一起，
  且你无法区分"我改坏的"与"别人改的"。
- **要求**：开工前确认稳健性轮已被接受并提交（建议单独一个 commit，
  例如 `Accept robustness round (v0.0.6.001)`），然后功能轮从该 commit 起分支。
- 若你发现 `git status` 里稳健性轮的改动仍在 → **停下来问操作方**，不要自行替他们提交
  别人的在飞工作，也不要直接往上叠。

`git status` 里应当看到（提交后这些应消失）：

```
 M DESCRIPTION / NAMESPACE / NEWS.md / .Rbuildignore
 M R/dr.R / R/silinfo.R / R/method-dr-extract.R / R/method-fortify.R / R/available_methods.R
 M man/*.Rd / tests/testthat/*.R
?? .github/  .workbuddy-ai/  ROBUSTNESS-REVIEW.md  tests/testthat/test-fortify.R
```

---

## 3. 本轮边界

**In scope**：
- F1 `nk()` 可插拔聚类方法（含 F5 依赖的内部结构规范化）
- F2 `dr_compare()` 多方法批量比较
- F3 `DrResult` 扩展槽
- F4 文档宣称方法的测试覆盖补齐
- F5 细粒度轮廓导出与轮廓条形图

**Out of scope**：
- 重写 `dr_extract` 的分派机制（`env_name(environment(fun))` 那套）——稳定且够用
- 把 `nk()` / `dr()` 改成 S4 或 R6
- 任何为了"支持更多方法"而放松稳健性轮定下的输入校验
- 用假数据/假徽章充数

### 需要操作方确认（默认值已给出，未确认前按默认执行并标注）

| 议题 | 默认 | 说明 |
| --- | --- | --- |
| 本轮版本号 | **`0.0.6.002`** | 沿用操作方 `.001` 的开发版本号约定；**发行版本号仍由操作方自己决定** |
| `DrResult` 扩展槽命名 | **`extra`** | 不要叫 `metadata`（该名字已被 `fortify()` / `autoplot()` 的样本级 metadata 占用） |

---

## 4. 硬性不变量（违反即失败）

1. **`R CMD check` 保持 `0 errors / 0 warnings / 0 notes`。**
2. **现有 120 个断言必须继续通过**，测试不得被削弱或删除。
3. **默认路径数值级不变**：`nk(data, k)`（不传 `fun`）与现在**逐位一致**；
   `dr()` 对已有方法的行为不变。这条靠测试固定，不靠"看起来对"。
4. **不重排/不重格式化**无关代码（`importFrom` 顺序、Rd 风格、既有注释）。
5. **`NAMESPACE` 同一时间只能有一个写者**（见第 7 节）。
6. **不 commit / 不 push**，除非操作方明确要求。
7. **不许把 UNVERIFIED 写成已验证**。本机装不上的包（`vegan` / `smacof` / `ecodist` /
   `ade4` / `labdsv`）不得凭文档臆断其行为。

---

## 5. 已验证事实（写代码前必读，含实测输出）

### F-A — `nk()` 当前对聚类方法是硬编码的，且内部结构是 pam 私有形状

`nk()` 调 `pam(data, k=i)` 后取 `x$silinfo`，其形状（实测）：

```r
str(pam(iris[,-5], 3)$silinfo, max.level=1)
# List of 3
#  $ widths         : num [1:150, 1:3]        ← 列名 cluster, neighbor, sil_width
#  $ clus.avg.widths: num [1:3] 0.798 0.417 0.451
#  $ avg.width      : num 0.553
```

消费这个形状的地方有三处，**任何规范化都必须保持这个形状，否则要连带改三处**：

- `summary.silinfo()` → `x$avg.width`（`vapply(..., FUN.VALUE = numeric(1))`）
- `print.silinfo()` → 经 `summary()`
- `autoplot.silinfo(object, k=)` → `object$silinfo[object$k == k][[1]]$widths[, "cluster"]`

### F-B — 存在一条**通用**的轮廓计算路径，且能逐位复现 pam 的数值

```r
x <- iris[,-5]; d <- dist(x); p <- cluster::pam(x, 3)
s <- cluster::silhouette(p$clustering, d)

dim(s)            # 150 x 3
colnames(s)       # "cluster" "neighbor" "sil_width"
class(s)          # "silhouette"    ← 注意：是 matrix 型对象，不是 list
attributes(s)     # dim, dimnames, Ordered, call, class   ← 没有 avg.width 属性！

mean(s[, "sil_width"])                                  # 0.552819
p$silinfo$avg.width                                    # 0.552819   ← 完全一致
tapply(s[, "sil_width"], s[, "cluster"], mean)          # 0.79814 0.41732 0.451105
p$silinfo$clus.avg.widths                              # 0.79814 0.41732 0.451105  ← 完全一致
summary(s)$avg.width                                   # 0.552819（class "summary.silhouette"）
```

**结论（这是 F1 的设计基石）**：`nk()` 可以对任意聚类器统一这样做——
取标签 → `cluster::silhouette(labels, d)` → 组装成 pam 形状的 list：

```r
list(widths          = as.matrix(s),
     clus.avg.widths = as.numeric(tapply(s[, "sil_width"], s[, "cluster"], mean)),
     avg.width       = mean(s[, "sil_width"]))
```

这样 `summary` / `print` / `autoplot` **一行都不用改**。已实测 `kmeans$cluster` 与
`cutree(hclust(d), 3)` 的标签走同一路径都能算出轮廓值。

### F-C — 各方法的"需要 data 还是 dist"不一致（F1 的主要设计张力）

| 聚类器 | 接受 | 取标签的方式 |
| --- | --- | --- |
| `cluster::pam` | data 或 dist | `$clustering` |
| `stats::kmeans` | **必须是 data（矩阵）**，喂 dist 会算错 | `$cluster` |
| `stats::hclust` | **必须是 dist**，喂矩阵会报错 | 需 `cutree(obj, k)` |

→ 不存在"统一喂 data"或"统一喂 dist"都能对的方案。**契约必须显式写死**（见 F1 任务）。

### F-D — 已安装方法的真实可用性（本轮覆盖测试的事实基础）

| 方法 | 实测 | 备注 |
| --- | --- | --- |
| `stats::prcomp` | ✓ 150x4 | 有 eigenvalue |
| `stats::cmdscale` | ✓ 150x2 | 默认返回裸矩阵，靠稳健性轮的 `dr_extract.matrix` 兜底 |
| `Rtsne::Rtsne` | ✗ `Remove duplicates before running TSNE.` | iris 有重复行；`check_duplicates=FALSE` 可通过 |
| `uwot::umap` | ✓ 150x2 | |
| `uwot::tumap` | ✓ 150x2 | |
| `uwot::lvish` | ✓ 150x2 | 小样本会报 `perplexity can be no larger than 29`（上游限制） |
| `ape::pcoa` | ✓ 150x4 | 有 eigenvalue |
| `MASS::sammon` | ✓ 149x2 | iris 原始距离会报 `zero or negative distance`（上游）；用去重数据可跑 |
| `ecodist` / `ade4` / `labdsv` / `smacof` / `vegan` | **未安装，UNVERIFIED** | 对应 `dr_extract.*` 方法本轮不动、不臆断 |

### F-E — 多方法结果的维度不一致，且单个方法失败是常态

```r
dim(dr(iris[,1:4], prcomp)$drdata)          # 150 x 4
dim(dr(iris[,1:4], uwot::umap)$drdata)      # 150 x 2   ← 维度数不同
```

失败是**常见**而非例外（F-D 里 `Rtsne` 与 `lvish` 的真实报错）。
→ `dr_compare()` 必须**逐方法隔离错误**，不能让一个方法挂掉整批调用。

### F-F — `fortify()` 只返回坐标，扩展槽不会自动流到图里

```r
fortify.DrResult <- function(model, data, metadata = NULL, ...) {
    res <- model$drdata          # ← 只取这一个字段
    ...
}
```

→ 给 `DrResult` 加 `extra` 槽后，**除非同时改 `fortify()`，否则图里拿不到它**。
`print.DrResult` 只读 `x$eigenvalue` / `x$stress` / `x$drdata` → 加字段是加性改动、安全，
但打印输出不应变化。

---

## 6. 工作单元

### Phase 1（四单元并行，文件互不相交）

#### F1 — `nk()` 支持可插拔聚类方法

**文件范围**：`R/silinfo.R`、`tests/testthat/test-silinfo.R`

**任务**：加 `fun`（默认 `cluster::pam`）与 `...`，让用户换聚类方法，同时**默认路径数值不变**。

**建议契约（写进 roxygen，并给出 pam / kmeans / hclust 三个示例）**：

```
fun(data, k, ...) 必须返回其中之一：
  (a) 长度为 n 的整数标签向量；或
  (b) 一个能取出标签的聚类对象（pam → $clustering，kmeans → $cluster，
      以及 inherits(obj, "hclust") 时自动 cutree(obj, k)）
nk() 负责相异度与轮廓计算：data 已是 dist 就用它，否则用 stats::dist(data)。
```

- `hclust` 场景通过 `inherits(obj, "hclust")` 自动 `cutree` 来兜住，避免要求用户自己写 wrapper
- 也可接受用户直接传标签向量（契约 (a)）
- 规范化按 **F-B** 的配方组装成 pam 形状 list
- 保持 `nk()` 返回对象的 `$data` / `$k` 字段语义不变
- **不要**改 `summary` / `print` / `autoplot` 的签名

**验收**：
- 默认调用与改动前**逐位一致**（对 `nk(iris[,-5], 2:4)` 的 `summary()` 结果逐值断言；
  轮廓值可用 F-B 的 `0.552819` 这类具体数字固定）
- `nk(iris[,-5], 2:4, fun = stats::kmeans)` 可用，且 `summary()` / `print()` / `autoplot()`
  三条下游路径都不报错
- `nk(..., fun = stats::hclust)` 可用（走自动 cutree）
- `k=1` / `k>=n` / 非整数 仍按稳健性轮的报错行为拒绝
- `dist` 输入仍可用（`nk(as.dist(dist(iris[,1:4])), 2:3)` 与改动前一致）

#### F2 — `dr_compare()` 多方法批量比较

**文件范围**：新建 `R/dr-compare.R`、新建 `tests/testthat/test-dr-compare.R`、
`NAMESPACE`（**Phase 1 中只有本单元碰 NAMESPACE**）

**任务**：一个高层便捷函数，一次跑多种降维方法并给出可比较的结果。

**建议签名与行为**：
```r
dr_compare(data, funs = list(prcomp = stats::prcomp), dim = 1:2,
           metadata = NULL, ...)
```
- **逐方法 `tryCatch`**（F-E）：单个方法失败不影响其他方法
- 返回值建议为一个 `DrCompare` 对象（list），含：
  - `results`：命名 list，成功项为 `DrResult`，失败项为错误对象/`NULL`
  - `summary`：`data.frame`（`method`、`status`、`n`、`k`、`has_eigenvalue`、`has_stress`、
    失败时的 `error` 信息）——**这是本单元的主要价值**：一张"哪些方法跑通了"的表
  - 不返回假数据：失败方法不得塞进占位坐标
- 绘图：用**不需要新依赖**的做法——把各方法结果统一切到 `dim`（默认前 2 维）、
  重命名为 `Dim1`/`Dim2`、拼成长表 + `facet_wrap(~method, scales = "free")`。
  **不要**为此把 `patchwork` 加进 `Imports`（除非操作方同意）。
- 维度不足（某方法只返回 1 维）时按清晰规则处理（报错或跳过并记入 `summary`，需写明）

**验收**：
- 混合"能跑 + 会失败"的方法时（例如 `list(prcomp = prcomp, tsne = Rtsne::Rtsne)`，
  iris 上 tsne 会失败），调用**不中断**，`summary` 里能看到失败方法及其真实错误信息
- 全部成功时绘图能正常 facet 出多面板
- `dr_compare(iris[,1:4], list(pca = prcomp, umap = uwot::umap))` 的 `results` 长度、各元素
  维度、`summary` 的 `status` 都有断言

#### F3 — `DrResult` 扩展槽

**文件范围**：`R/dr.R`、`R/method-fortify.R`、`tests/testthat/test-dr.R`、
`tests/testthat/test-fortify.R`

**任务**：给 `DrResult` 一个放"方法特有附加信息"的地方，为将来（局部密度、knn 索引、
聚类标签等）留出接口，**本轮不要求任何 `dr_extract.*` 真的填它**。

- 在 `as.dr()` 的 `structure(list(...))` 里新增 `extra` 字段，取 `dr_result$extra`，
  默认 `NULL`（现有 `dr_extract.*` 都不返回该元素 → `NULL`，天然向后兼容）
- **命名用 `extra`，不要用 `metadata`**（F-F 与第 3 节）
- `fortify.DrResult`：把 `extra` 中**逐样本、长度等于 n** 的元素合并进返回的 data.frame，
  使其可绘图；命名冲突要有明确策略（例如跳过并 warning，或加前缀）。
  若你认为"不合并"更稳妥，必须在报告里说明理由并写测试固定该决定
- `print.DrResult` 的输出**不得变化**（不打印 `extra`）
- roxygen 里说明 `extra` 的契约：一个 list，元素名将成为可绘图的列名

**验收**：构造一个 `extra` 非空的 `DrResult`（可手工 `structure()` 或写个返回 `extra` 的
测试用 `dr_extract` 方法），断言：`print()` 输出与无 `extra` 时一致；
`fortify()` 能按你的策略拿到/跳过它；`autoplot()` 不报错。

#### F4 — 文档宣称方法的测试覆盖补齐

**文件范围**：`DESCRIPTION`（`Suggests`）、`R/available_methods.R`、
`tests/testthat/test-dr-extract.R`、`tests/testthat/test-available-methods.R`

**任务**：把 `available_methods()` 的"宣称"变成"有测试的事实"。

- 把 `vegan`、`smacof`、`ecodist`、`ade4`、`labdsv` 加进 `Suggests`
  （CI 已设 `_R_CHECK_FORCE_SUGGESTS_: false`，不会因此挂）
- 为每个宣称的方法写测试，**一律 `skip_if_not_installed()`**；本机可真实跑通的（F-D）必须写实断言：
  `prcomp`、`cmdscale`（含 `eig=TRUE` 的 list 路径）、`Rtsne`（用 `check_duplicates=FALSE`
  或去重数据）、`uwot::umap` / `tumap` / `lvish`、`ape::pcoa`、`MASS::sammon`（去重数据）
- 已验证的上游失败也要固定成测试（预期报错），避免将来被误判为包的问题：
  iris 上 `Rtsne` 因重复点失败、小样本 `lvish` 因 perplexity 失败
- 若某个宣称的方法经核查**无法**通过现有分派工作 → 明确处理：要么实现，要么从
  `available_methods()` 里移除并在 NEWS 说明。**不要留着假的宣称。**

**验收**：每个 `available_methods()` 条目或有一条测试、或有明确注释说明为何无法本地测试；
`skip_if_not_installed` 的 skip 数量在报告里列明。

### Phase 2（F1 落地后再做）

#### F5 — 细粒度轮廓导出与轮廓条形图

**文件范围**：`R/silinfo.R`、`R/method-autoplot.R`、`tests/testthat/test-silinfo.R`

**依赖**：F1 已提供稳定的 `widths` 矩阵（列 `cluster` / `neighbor` / `sil_width`）。
**不得**与 F1 并行改 `R/silinfo.R`。

**任务**：
- 导出细粒度轮廓：让用户能拿到逐样本的 `sil_width` 与逐簇均值（现在只能自己挖
  `object$silinfo[[i]]$widths`）。建议一个访问器（如 `silinfo_widths(x, k)`）返回
  data.frame（`sample`/`cluster`/`neighbor`/`sil_width`），或扩展 `summary()` 的返回
  ——**注意不要破坏 `summary()` 现有返回结构**（`K` + `Silhouette` 两列，已有测试依赖）
- 给 `autoplot.silinfo` 增加"轮廓条形图"模式：按簇分组、簇内按 `sil_width` 排序的条形图
  （这是 `cluster::silhouette` 自带 plot 的经典图，用 ggplot2 重做）。
  模式开关的设计由你定（如 `type = c("k", "pca", "silhouette")`），但**必须保持
  `autoplot(x)` 与 `autoplot(x, k=3)` 的现有行为不变**（有测试依赖）

**验收**：现有 `autoplot.silinfo` 测试不变且通过；新模式有测试；访问器的返回结构与
F1 的 `widths` 一致。

---

## 7. 编排

### 依赖与文件冲突

| 单元 | 独占文件 | 阶段 |
| --- | --- | --- |
| F1 | `R/silinfo.R`, `test-silinfo.R` | Phase 1 |
| F2 | `R/dr-compare.R`(新), `test-dr-compare.R`(新), **NAMESPACE** | Phase 1 |
| F3 | `R/dr.R`, `R/method-fortify.R`, `test-dr.R`, `test-fortify.R` | Phase 1 |
| F4 | `DESCRIPTION`, `R/available_methods.R`, `test-dr-extract.R`, `test-available-methods.R` | Phase 1 |
| F5 | `R/silinfo.R`, `R/method-autoplot.R`, `test-silinfo.R` | **Phase 2**（依赖 F1；且 NAMESPACE 需在 F2 之后） |

Phase 1 的四个单元文件范围互不相交 → **可同一条消息里全部并发启动**。
`NAMESPACE` 在 Phase 1 只有 F2 一个写者；F5 因可能新增导出且要改 `R/silinfo.R`，必须排在
F1、F2 之后。`man/` 的重新生成统一放在集成步骤（第 8 节），不要让各单元各自跑 `document()`。

### 建议线路分配（只用 qoder 与 workbuddy，**不要用 cline**）

| 单元 | 建议线路 | 理由 |
| --- | --- | --- |
| F1 | workbuddy | 契约设计有真实张力（F-C），且要保证数值逐位不变 |
| F2 | qoder | 结构清晰：tryCatch + 长表 + facet |
| F3 | workbuddy | 触及 `DrResult` 结构与 `fortify` 语义，需判断向后兼容 |
| F4 | qoder | 以测试与 DESCRIPTION 为主，机械性较强 |
| F5 | workbuddy | 需在 F1 的 `widths` 结构上做图与访问器，且不能破坏现有行为 |

### 工作树隔离（推荐）

与稳健性轮相同：每单元一个 worktree，避免并行子代理互相踩到 `load_all()` 的中间状态。

```bash
cd /home/wang/data/source/tidydr
git worktree add ../tidydr-f1 -b feature/f1-nk-pluggable
git worktree add ../tidydr-f2 -b feature/f2-dr-compare
git worktree add ../tidydr-f3 -b feature/f3-drresult-extra
git worktree add ../tidydr-f4 -b feature/f4-method-coverage
# F5 等 Phase 1 合并后再开
```

退化方案：单工作树并行改，但每单元只跑自己的 `test_file()`，全量验证推迟到集成。

---

## 8. 集成步骤与完成定义

1. **合并** Phase 1 各分支（解决 `NAMESPACE` 冲突：只有 F2 改过它）。
2. **再做 F5**（Phase 2），然后合并。
3. **一次性重生成文档**（此时才跑）：
   ```bash
   cd /home/wang/data/source/tidydr
   Rscript -e 'devtools::document()'
   git diff    # 逐行甄别
   ```
   **务必** revert 掉 roxygen 8.1.0 带来的无关 churn（`importFrom` 多行重排、
   `man/reexports.Rd` 链接风格、`man/tidydr-package.Rd` 作者重排、
   `Config/roxygen2/version`），并确认 `DESCRIPTION` 仍是 `RoxygenNote: 7.3.2`。
   稳健性轮已把这条纪律验证过一遍，照做即可。
4. **全量测试**：期望 120（基线）+ 本轮新增，0 failures。
5. **全量 check**：期望 `0 errors / 0 warnings / 0 notes`。
6. **版本与 NEWS**：`Version: 0.0.6.002`（默认，见第 3 节），`NEWS.md` 顶部加
   `# tidydr 0.0.6.002` 段落，逐条记录本轮 5 类改动。**发行版本号仍归操作方。**
7. **报告**（第 9 节），**不 commit / 不 push** 除非操作方明确要求。

### 完成定义（DoD）

- [ ] F1：`nk()` 支持 `fun`/`...`；默认路径数值逐位不变；kmeans 与 hclust 可用
- [ ] F2：`dr_compare()` 逐方法隔离错误；`summary` 表能报出失败方法与原因；绘图 facet 正常
- [ ] F3：`DrResult` 有 `extra` 槽；`print` 输出不变；`fortify` 策略明确且有测试
- [ ] F4：`available_methods()` 的每个条目都有测试或明确的"为何不能本地测"说明；
       `vegan`/`smacof`/`ecodist`/`ade4`/`labdsv` 已进 `Suggests`；无假宣称残留
- [ ] F5：细粒度轮廓可导出；轮廓条形图可用；现有 `autoplot(x)` / `autoplot(x, k=3)` 行为不变
- [ ] `R CMD check` = 0/0/0；全量测试 0 failures
- [ ] 未触碰 Out of scope；未 commit / 未 push

---

## 9. 交付报告格式

```
### F? — <标题>
改动文件：<路径列表>
diff：<git diff 输出或 --stat + 关键片段>
新增测试：<文件:行> + 断言意图
验证命令与真实输出：<粘贴原文>
UNVERIFIED / 需要决策：<没有就写"无">
```

集成报告额外包含：全量测试汇总、`R CMD check` 的 `Status:` 行、
以及"哪些结论未经真实环境验证"（未安装包、CI 未真跑等）。

---

## 附录 A — 关键事实的一次性复现

```bash
cd /home/wang/data/source/tidydr
Rscript -e '
suppressMessages(devtools::load_all(".", quiet=TRUE))

cat("### F-A pam silinfo 形状\n")
str(cluster::pam(iris[,-5], 3)$silinfo, max.level=1)

cat("\n### F-B 通用路径能复现 pam 的数值\n")
x <- iris[,-5]; d <- dist(x); p <- cluster::pam(x, 3)
s <- cluster::silhouette(p$clustering, d)
cat("mean(sil_width)   :", mean(s[, "sil_width"]), "\n")
cat("pam$avg.width     :", p$silinfo$avg.width, "\n")
cat("MATCH:", isTRUE(all.equal(mean(s[,"sil_width"]), p$silinfo$avg.width)), "\n")
cat("attributes(s):", paste(names(attributes(s)), collapse=","), "  <- 无 avg.width 属性\n")

cat("\n### F-D 方法可用性\n")
probe <- function(lbl, e) {
  r <- tryCatch(e, error=function(err) paste("ERROR:", conditionMessage(err)))
  cat(sprintf("%-22s %s\n", lbl, if (is.character(r)) r else paste("OK", paste(dim(r$drdata), collapse="x"))))
}
probe("prcomp",   dr(iris[,1:4], stats::prcomp))
probe("cmdscale", dr(as.dist(dist(iris[,1:4])), stats::cmdscale))
probe("Rtsne",    dr(iris[,1:4], Rtsne::Rtsne))
probe("umap",     dr(iris[,1:4], uwot::umap))
probe("tumap",    dr(iris[,1:4], uwot::tumap))
probe("lvish",    dr(iris[,1:4], uwot::lvish))
probe("pcoa",     dr(dist(iris[,1:4]), ape::pcoa))

cat("\n### F-E 维度不一致\n")
cat("prcomp:", paste(dim(dr(iris[,1:4], stats::prcomp)$drdata), collapse="x"), "\n")
cat("umap  :", paste(dim(dr(iris[,1:4], uwot::umap)$drdata), collapse="x"), "\n")
' 2>&1
```

## 附录 B — 源码位置索引

| 内容 | 位置 |
| --- | --- |
| `nk()` / `validate_nk_*` / `print.silinfo` / `summary.silinfo` | `R/silinfo.R`（169 行） |
| `autoplot.silinfo`（含 `$widths[, "cluster"]` 用法） | `R/method-autoplot.R` |
| `dr()` / `as.dr()`（`DrResult` 组装处） / `print.DrResult` | `R/dr.R` |
| `dr_extract` 泛型与各方法（含新的 `dr_extract.matrix`） | `R/method-dr-extract.R` |
| `fortify.DrResult`（只返回 `$drdata`） | `R/method-fortify.R` |
| `available_methods()` 及其新契约说明 | `R/available_methods.R` |
| 稳健性轮的交接单与执行报告 | `HANDOFF-robustness.md`、`ROBUSTNESS-REVIEW.md` |
