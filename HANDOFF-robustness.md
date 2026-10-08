# HANDOFF — tidydr 稳健性加固（Robustness Round）

> 这份文档是给**执行方 AI** 的工作交接单。所有"缺陷"都已在本文档中实测复现过，
> 不是猜测；所有命令都可直接粘贴执行。请先读第 3 节（硬性不变量）和第 7 节（已知坑）
> 再动手。

---

## 0. 一句话任务

在不改变现有正常行为的前提下，给 `tidydr` 加上：**输入校验、边界保护、失败可见性、
承诺与实现一致、CI**。产出 = 源码 + 测试 + 一个能自动跑 `R CMD check` 的 workflow，
最终 `R CMD check` 保持 `0 errors / 0 warnings / 0 notes`。

---

## 1. 起点与环境

| 项 | 值 |
| --- | --- |
| 仓库绝对路径 | `/home/wang/data/source/tidydr` |
| 当前 HEAD | `733e9e2`（"Fix bugs, harden error handling, add tests and README"） |
| 分支 | `master`，**领先 `origin/master` 1 个 commit（尚未 push）** |
| R 版本 | 4.6.1 (2026-06-24) |
| 工作树状态 | 干净（本文件已提交，见第 8 节） |

**已安装（可本地验证）**：`devtools 2.5.2`、`testthat 3.3.2`、`roxygen2 8.1.0`、
`usethis 3.2.2`、`gh 1.6.1`、`pkgdown 2.2.1`、`yaml 2.3.12`、`cluster 2.1.8.2`、
`MASS 7.3.66`、`Rtsne 0.17`、`uwot 0.2.5`、`ape 5.8.1`。

**未安装（相关测试必须 `skip_if_not_installed()`）**：`ecodist`、`ade4`、`labdsv`、
`smacof`、`vegan`、`covr`。

**开始前先跑这三条，确认基线**：

```bash
cd /home/wang/data/source/tidydr

# 1) 测试基线：应为 "37 assertions, 0 failures"
Rscript -e 'devtools::load_all("."); testthat::test_dir("tests/testthat", reporter="summary")'

# 2) check 基线：应为 0 errors / 0 warnings / 0 notes
Rscript -e 'devtools::check(document=FALSE, cran=FALSE, error_on="never")'

# 3) 确认工作树干净
git status --short   # 期望：无输出
```

上一轮（commit `733e9e2`）已经修掉的问题，**不要重复修**：`print.DrResult` 的 `sprintf`
崩溃、`dr_extract.default` / `as.dr()` 的静默 NULL、`autoplot.silinfo` 的非法 k 报错、
死代码清理、`aes_()`/`aes_string()` 迁移、`print.silinfo` 的轮廓宽度输出、README、测试骨架。

---

## 2. 本轮边界

**In scope（只做这些）**：输入契约校验、边界值保护、返回值可打印/可绘图、
`fortify()` 的 metadata 类型处理、`available_methods()` 的承诺兑现、CI。

**Out of scope（明确不做，留给功能路线图）**：
- `dr_compare()` 之类的多方法批量比较高层函数
- 把 `nk()` 改成可插拔 `fun`（当前写死 `cluster::pam`）
- `DrResult` 增加 `metadata`/`extra` 扩展槽
- 把 `vegan` 等加进 `Suggests` 并补全其测试覆盖
- **`dr_extract` 分派机制的整体重构**：只在 U4 范围内做"矩阵返回值"的收口，
  不要重写 `env_name(environment(fun))` 这套机制（见 U4 与第 7 节第 4 条）

---

## 3. 硬性不变量（违反即视为失败）

1. **`R CMD check` 必须保持 `0 errors / 0 warnings / 0 notes`**。任何新 NOTE 都必须修掉，
   不允许"留一个 NOTE 说明理由"。
2. **现有 37 个断言必须继续通过**，且现有测试文件不得为了让新代码通过而被削弱/删除。
3. **`dist` 对象路径必须继续可用**。文档承诺 `dr()` 的 `data` 可以是距离矩阵/距离对象
   （`R/available_methods.R` 的 `distance_methods`、vignette 的说明）。注意：
   `is.vector(as.dist(x))` 是 `FALSE`、`is.matrix(as.dist(x))` 是 `FALSE`，
   所以**校验条件不能只写 `is.vector || is.matrix`**，否则会把合法输入拒掉。
4. **`fortify()` 的 `.group` 行为不能变**：`vector`/`factor` 类型的 metadata 仍要落到
   名为 `.group` 的列（vignette 与 `dr()` 的 `@examples` 依赖
   `autoplot(x, aes(color=.group), metadata=iris$Species)`）。
5. **不重排/不重格式化**与本次任务无关的代码，包括 importFrom 顺序、Rd 文件风格。
6. **不 commit、不 push**，除非操作方明确要求（默认把改动留在工作树里，报告 diff）。

---

## 4. 已验证的缺陷清单（含实测输出）

以下 5 项全部在 `733e9e2` 上实测复现过。**结论已核实，不要凭直觉改动事实描述**。

### R1 — `dr()` 对 `data` 没有任何校验，非法输入会静默产出无意义结果

```r
dr(NULL, prcomp)        # Error: 'data' must be of a vector type, was 'NULL'   ← 来自 prcomp，不是 tidydr
dr(1:10, prcomp)        # ★ 静默"成功"，返回 10 x 1 的 DrResult（只有 Dim1 一列）
d <- iris[1:5,1:4]; d[1,1] <- NA
dr(d, prcomp)           # Error: infinite or missing values in 'x'            ← 来自 prcomp，不是 tidydr
```

其中 `dr(1:10, prcomp)` 最危险：**一个裸数值向量被当成正常输入，产出一个看起来合法的
`DrResult`**，用户要等到下游画图/建模才发现是垃圾。这是本次要收的第一个口子。

### R2 — `nk()` 的 `k` 边界会产出**无法打印**的对象

```r
x <- nk(iris[,-5], 1)   # nk() 本身不报错
print(x)                # Error in vapply(...): values must be length 1,
                        #   but FUN(X[[1]]) result is length 0
nk(iris[,-5], c(2,1))   # 同样坏（只要含 k=1）
nk(iris[,-5], 200)      # Error: Number of clusters 'k' must be in {1,2, .., n-1}; hence n >= 2  ← 来自 pam
```

根因：`cluster::pam(data, k=1)` 的 `silinfo$avg.width` 是 `NULL`（k=1 时轮廓系数无定义），
而 `summary.silinfo()` 用 `vapply(..., FUN.VALUE = numeric(1))` 提取该值 → 长度 0 直接抛错。
连带影响：`print.silinfo()`、`summary()`、`autoplot(silinfo)` 全部炸。
注意 `k=1` 是 `pam()` 的**合法**输入，所以这是 tidydr 必须自己处理的边界，不能甩给上游。

### R3 — `fortify()` 对 metadata 的两种静默失败

```r
x <- dr(iris[,1:4], prcomp)

# (a) matrix 类型：完全静默丢弃，连 warning 都没有
fortify(x, metadata = matrix(1:300, nrow = 150))
# → ncol 仍为 4，列名仍是 Dim1..Dim4，没有任何提示

# (b) 长度等于 n 的 list：静默"污染"，产出 154 列
fortify(x, metadata = as.list(1:150))
# → ncol = 154，列名 Dim1..Dim4, .group.1L, .group.2L, ..., .group.150L
```

根因：函数只处理 `is.vector(metadata) || is.factor(metadata)` 和 `is.data.frame(metadata)`
两条分支；**`matrix` 两个条件都为 FALSE → 直接被跳过且无提示**；而
**`is.vector(as.list(1:150))` 是 `TRUE`**（R 的 `is.vector` 对纯 list 返回 TRUE），
于是 list 走进 vector 分支被 `cbind` 成 n 个垃圾列。
(b) 比 (a) 更糟：不是"没生效"，而是"以错误方式生效"。

### R4 — `available_methods()` 宣称支持的 `stats::cmdscale()` 实际不可用

```r
d <- as.dist(dist(iris[,1:4]))
dr(d, stats::cmdscale)
# → WARN: Unable to extract DR coordinates from the result (no 'points' field found)...
# → 随后 stop（坐标为空）
```

根因链：`cmdscale(d)` 默认返回**裸 matrix**（`class` 为 `c("matrix","array")`，没有任何
可识别 class）→ `as.dr()` 把包名字符串前置成 `c("stats","matrix","array")` →
`dr_extract.default` 只认 `points`/`eig`/`stress` 字段 → 取不到坐标 → 失败。
而 `available_methods("distance")` 里第 1 条就是 `stats::cmdscale()`。

**同一根因的第二个受害者**（实测）：

```r
dr(iris[,1:4], uwot::umap)                    # OK（150x2）
dr(iris[,1:4], function(d) uwot::umap(d))     # ★ 失败，同一条 warning+stop
dr(iris[,1:4], function(d) prcomp(d))         # OK（150x4）
dr(iris[,1:4], function(d) Rtsne::Rtsne(d, check_duplicates=FALSE))  # OK（150x2）
```

**重要更正**：包装函数（wrapper）**并非一律分派失败**。只要返回对象自带可识别 class
（`prcomp` → `"prcomp"`、`Rtsne` → `"Rtsne"`），class 链里仍有它，S3 照样能命中对应
`dr_extract.*` 方法。真正失败的是**返回裸 matrix 的方法被包一层之后**：未包装时
`where="uwot"` 把 `"uwot"` 前置进 class 从而命中 `dr_extract.uwot`；包装后
`where="R_GlobalEnv"`，class 变成 `c("R_GlobalEnv","matrix","array")`，没有任何方法接得住。
→ 结论：缺的是一个 **`matrix` 返回值兜底**，而不是重写分派机制。

**副作用记录（不是 bug，别改）**：`dr(d, MASS::sammon)` 在 iris 上报
`zero or negative distance between objects`，这是 `MASS::sammon` 自己拒绝该数据，与 tidydr 无关。

### R5 — 没有 CI

仓库无 `.github/` 目录。testthat 骨架刚建好，但没有自动执行者 → 相当于白测。
`covr` 未安装，本机也无法真正运行 GitHub Actions。

---

## 5. 工作单元

五个单元的文件范围**互不相交**，可全部并行（编排见第 6 节）。
每个单元都必须：改源码 → 加/改测试 → 跑通自己的测试 → 报告 diff 与测试输出。

### U1 — `dr()` 的输入契约

**文件范围**：`R/dr.R`、`tests/testthat/test-dr.R`
（如需内部 helper，放在 `R/dr.R` 内或新建 `R/validate.R`，**不要导出**）

**任务**：在校验层拦掉明显非法的 `data`，给出 tidydr 语境的报错（信息里提到 `dr()` 与
数据要求），而不是把底层包的报错直接甩给用户。

**必须拦掉**：
- `data` 为 `NULL`
- `data` 为裸数值向量且**不是** `dist` 对象（即 `dr(1:10, prcomp)` 这类；报错时提示
  "若这是距离对象请用 `as.dist()`；若要降维请提供 matrix / data.frame"）
- `data` 含 `NA` / `NaN` / `Inf`（报错信息说明需要先处理缺失值）
- `data` 是 data.frame 且含非数值列（iris 的 `Species` 这种；若你判断"允许 data.frame 带
  非数值列"更合理，必须在报告里说明理由并写测试固定该行为——但 `dr(iris, prcomp)` 这种
  应当给出可读提示，而不是 prcomp 的 `'x' must be numeric`）

**必须保持可用**：`matrix`、数值 `data.frame`、`dist` 对象、以及现有的
`dr(iris[,1:4], prcomp)` 全部照旧（现有测试即回归网）。

**验收**：上述每种非法输入都有断言其报错信息包含可识别的关键词；`dist` 对象有正向测试
（例如 `dr(as.dist(dist(iris[,1:4])), function(d) cmdscale(d))` 在 U4 完成后应可用；
U1 自身可先用 `dr(as.dist(dist(iris[,1:4])), ape::pcoa)` 这种已装包做正向断言）。

### U2 — `nk()` 的边界与"永远可打印"

**文件范围**：`R/silinfo.R`、`tests/testthat/test-silinfo.R`

**任务**：
- 入口校验 `k`：含 `1`（或任何使 `avg.width` 为 `NULL` 的值）→ 立即 `stop()`，信息说明
  "k 至少为 2，k=1 时轮廓系数无定义"；`k >= n`（n = 样本数）→ 清晰报错，不要只留 pam 的
  原始信息；`k` 非数值/非整数 → 报错
- 校验 `data`（与 U1 同风格，但**各自独立实现，不要跨单元共享 helper**，
  见第 6 节的耦合说明）
- 保证 `nk()` 的返回对象在任何合法 `k` 下都能 `print()` / `summary()` / `autoplot()`

**不要**为了让 `k=1` "能用"而把 `summary.silinfo()` 改成容忍 `NULL`——轮廓系数在 k=1 时
无定义，静默返回 `NA` 属于制造新的静默失败。**报错是正确行为。**

**验收**：`nk(iris[,-5], 1)` 报清晰错误；`nk(iris[,-5], c(2,1))` 报清晰错误；
`nk(iris[,-5], 2:4)` 行为不变（回归）；`print()` / `summary()` / `autoplot()` 各有断言。

### U3 — `fortify()` 的 metadata 类型处理

**文件范围**：`R/method-fortify.R`、新建 `tests/testthat/test-fortify.R`

**任务**：消除 R3 的两种静默失败。

**行为规范**：
| metadata 类型 | 期望行为 |
| --- | --- |
| `vector` / `factor` | 长度 == n 时 → `cbind(res, .group=metadata)`；长度 != n → `warning()`（保持现状） |
| `data.frame` | 行数 == n 时 → `cbind(res, metadata)`；行数 != n → `warning()`（保持现状） |
| `matrix` | **不得静默丢弃**。推荐 `as.data.frame(metadata)` 后按 data.frame 路径走；行数不符则 `warning()` |
| 其他（含 `list`） | **`warning()` 并忽略**，信息里列出支持的类型 |

**关键实现注意**：`is.vector(as.list(1:n))` 返回 `TRUE`，所以判断顺序上必须**先把 list
排除掉**（例如用 `is.atomic(metadata)` 判定真正的向量，或在 vector 分支里加 `!is.list()`）。
必须为 `as.list(1:150)` 写一个回归测试，断言结果**不再**出现 `.group.1L` 之类的列、
且 `ncol == 4`。

**验收**：matrix 不再静默丢弃；长度 n 的 list 不再产生垃圾列；vector/factor/data.frame
三态行为与现状一致（含 `.group` 命名）；上述每种都有断言。

### U4 — `available_methods()` 的承诺兑现（矩阵返回值兜底）

**文件范围**：`R/method-dr-extract.R`、`R/available_methods.R`、
`tests/testthat/test-available-methods.R`、`tests/testthat/test-dr-extract.R`、
`NAMESPACE`、`man/`（**本回合只有这个单元需要碰 NAMESPACE 和 man/**）

**任务**：让 R4 中"宣称支持但实际不可用"的 `stats::cmdscale()` 真正可用，做法是补一个
**`matrix` 返回值的兜底方法**：

```r
##' @method dr_extract matrix
##' @export
dr_extract.matrix <- function(result) {
    # 建议：要求 is.numeric(result) 且 ncol(result) >= 2
    # 满足 → list(drdata = as.data.frame(result), eigenvalue = NULL, stress = NULL)
    # 不满足 → stop()/warning()，保持与 dr_extract.default 一致的"不静默"原则
}
```

**分派顺序必须验证**（这是本单元最容易搞错的地方）：
- `dr(iris[,1:4], uwot::umap)` → class 链 `c("uwot","matrix","array")` →
  必须**仍然**命中 `dr_extract.uwot`（而非新的 `.matrix`）。因为 `"uwot"` 在 class 链里
  排在 `"matrix"` 前面，S3 会先找到它 —— 但**必须写测试固定这一点**，否则一旦将来有人
  调整 class 顺序就会静默改变行为。
- `dr(as.dist(dist(iris[,1:4])), stats::cmdscale)` → class 链 `c("stats","matrix","array")`
  → `dr_extract.stats` 不存在 → 落到 `dr_extract.matrix` ✓
- `dr(iris[,1:4], function(d) uwot::umap(d))` → `c("R_GlobalEnv","matrix","array")` →
  `dr_extract.matrix` ✓（**这个包装场景是本次兜底的主要收益之一**）

**契约要在文档里写清楚**：新增的 `dr_extract.matrix` 意味着"任何返回数值矩阵的降维方法
都可被接受"。请在 `dr_extract.matrix` 的 roxygen 与 `available_methods()` 的输出里
把这条契约说明白，避免它变成一个隐形的宽松入口。

**必须补的负向测试**：返回**非数值** matrix、或只有 **1 列**的 matrix → 报错/警告，
不得静默接受（这是 U4 与 U1"不收垃圾输入"精神一致的地方）。

**本机未安装的包**：`ecodist` / `ade4` / `labdsv` / `smacof` / `vegan` 相关方法
**不要臆断其行为**，相关测试一律 `skip_if_not_installed()`。`Rtsne` / `uwot` / `ape` /
`MASS` / `cmdscale` 已装，可以也必须写真实测试。

### U5 — CI

**文件范围**：`.github/workflows/`（新建）、`README.md`（仅可选加 badge）

**任务**：新建 `.github/workflows/R-CMD-check.yaml`，在 push/PR 时自动跑 `R CMD check`。

**要求**：
- 用官方 `r-lib/actions`（`setup-r@v2` + `setup-r-dependencies@v2` + `check-r-package@v2`，
  或 `rcmdcheck`），不要自己发明步骤
- 矩阵覆盖 `ubuntu-latest`（`release` / `devel` / `oldrel-1`）+ `macos-latest` + `windows-latest`
- 注意 `Suggests` 里的包（`SingleCellExperiment` / `SummarizedExperiment` / `prettydoc` 等）
  在 CI 上能否装成功；必要时在 `extra-packages` 里显式声明，或设
  `_R_CHECK_FORCE_SUGGESTS_: false`（`R CMD check` 默认该值为 true，任何 Suggests 装不上
  都会让 CI 挂）
- **不要**添加假的覆盖率数字或 CI 徽章（本机没有覆盖率数据、workflow 也尚未真实跑过）；
  如果加 badge，只能在确认 workflow 文件语法与结构无误后加"R-CMD-check"这一个

**验收**：本机无法运行 Actions，因此要求
`Rscript -e 'yaml::read_yaml(".github/workflows/R-CMD-check.yaml")'` 能成功解析，
并逐行对照 `r-lib/actions` 官方 README 的示例确认无结构错误。在报告里明确写明
"未经真实 CI 运行验证"。

---

## 6. 编排

### 并行度与文件冲突

| 单元 | 独占文件 | 可并行 |
| --- | --- | --- |
| U1 | `R/dr.R`, `test-dr.R` | ✅ |
| U2 | `R/silinfo.R`, `test-silinfo.R` | ✅ |
| U3 | `R/method-fortify.R`, `test-fortify.R`(新) | ✅ |
| U4 | `R/method-dr-extract.R`, `R/available_methods.R`, `test-dr-extract.R`, `test-available-methods.R`, `NAMESPACE`, `man/` | ✅ |
| U5 | `.github/workflows/`(新), `README.md` | ✅ |

五个单元文件范围互不相交 → **可同一条消息里全部并发启动**。
**唯一共享文件是 `NAMESPACE`，只有 U4 需要改它**，其余单元不得触碰。

**建议线路分配**（按操作方指定，只用 qoder 与 workbuddy 两条线路，**不要用 cline**）：

| 单元 | 建议线路 | 理由 |
| --- | --- | --- |
| U1 | workbuddy | 需要理解 `dist` 语义与"不能误伤合法输入"的取舍 |
| U2 | workbuddy | 同上，需判断 k=1 该报错而非容忍 |
| U3 | qoder | 逻辑局部、边界清晰（`is.vector(list)` 这个坑写清楚即可） |
| U4 | workbuddy | 涉及 S3 分派顺序，最容易出错，值得用强档 |
| U5 | qoder | YAML + 文档，不需要 R 语义推理 |

### 工作树隔离（推荐）

并行子代理共用同一个工作树时，彼此的中间状态（哪怕只是语法临时不完整）会让
`devtools::load_all()` 失败、把别家的测试跑挂。两条路：

**方案 A（推荐）— 每单元一个 worktree**：

```bash
cd /home/wang/data/source/tidydr
git worktree add ../tidydr-u1 -b robustness/u1
git worktree add ../tidydr-u2 -b robustness/u2
git worktree add ../tidydr-u3 -b robustness/u3
git worktree add ../tidydr-u4 -b robustness/u4
git worktree add ../tidydr-u5 -b robustness/u5
```

各单元在自己的 worktree 里改+验证，最后由操作方合并（U4 与其余单元无文件冲突，可顺序 merge）。

**方案 B — 单工作树串行验证**：允许并行改文件，但每个单元验证时**只跑自己的测试文件**
（`testthat::test_file("tests/testthat/test-XX.R")`），并接受"兄弟单元的中间状态可能
干扰 `load_all()`"这一风险；全量验证推迟到第 8 节的集成步骤。

### 耦合禁令

**不要在 U1 与 U2 之间共享校验 helper**。跨单元共享会把两个本可并行的单元变成有依赖的
串行单元。各自实现最小校验逻辑；如果操作方希望之后收敛成一个内部 helper，那是集成阶段
之后的独立重构，不属于本轮。

---

## 7. 已知坑（先读，能省很多返工）

1. **`devtools::document()` 会引入大量无关 churn。** 本机 `roxygen2` 是 **8.1.0**，而
   `DESCRIPTION` 里写的是 `RoxygenNote: 7.3.2`。跑 `document()` 会：把 `importFrom`
   重排成多行分组格式、重写 `man/reexports.Rd`（`\link[ggplot2]{aes}` →
   `\link[ggplot2:aes]{aes()}`）、重排 `man/tidydr-package.Rd` 的作者列表、并新增
   `Config/roxygen2/version: 8.1.0`。
   → **对策**：优先**手工编辑** `NAMESPACE` / `man/*.Rd` 的最小必要行（上一轮就是这么做的）；
   若确实需要跑 `document()`，跑完必须 `git diff` 逐行甄别，把与本次任务无关的 churn
   `git checkout --` 掉。**绝对不要**把 roxygen 版本噪音混进提交。
2. **除 U4 外，任何单元都不要动 `NAMESPACE`。** 它是共享文件，并行改动必然冲突。
3. **`aes()` 里的裸列名会触发 `R CMD check` NOTE**：`no visible binding for global
   variable 'Dim1'`。本包已有惯例：在函数开头写 `Dim1 <- Dim2 <- NULL`
   （见 `R/method-autoplot.R` 的 `autoplot.DrResult`）。写新代码时沿用这个模式，
   否则 check 会从 0 NOTE 变成 1 NOTE，直接违反第 3 节第 1 条。
4. **不要重写 `dr_extract` 的分派机制**（`as.dr()` 里
   `where <- env_name(environment(fun))` 那套）。它在"返回对象自带 class"的情况下工作
   良好（见 R4 的更正）；本轮只补 `matrix` 兜底。整体重构是独立议题，需要先做设计评审。
5. **`is.vector()` 对纯 list 返回 `TRUE`** —— U3 的核心坑，见 R3。
6. **`is.vector(as.dist(x))` / `is.matrix(as.dist(x))` 都是 `FALSE`** —— U1 的核心坑，
   见第 3 节第 3 条。
7. **`pam(k=1)` 的 `silinfo$avg.width` 是 `NULL`**，不是 `NA` —— U2 的核心坑，见 R2。
8. `Rtsne::Rtsne(iris[,1:4])` 会因 iris 有重复点而报
   `Remove duplicates before running TSNE.`（上游行为，不是 tidydr 的 bug）。
   测试时用 `Rtsne(..., check_duplicates=FALSE)`。
9. `MASS::sammon` 在 iris 距离上会报 `zero or negative distance`（上游行为）。

---

## 8. 集成步骤与完成定义

所有单元落地后，由操作方（或指定一个集成单元）执行：

1. **合并**各 worktree/分支；解决可能的 `NAMESPACE` / `man/` 冲突（预期只有 U4 碰这两个）。
2. **一次性重生成文档**（此时才跑，避免并行冲突）：
   ```bash
   cd /home/wang/data/source/tidydr
   Rscript -e 'devtools::document()'
   git diff   # 逐行甄别，把 roxygen 版本噪音 revert 掉（见第 7 节第 1 条）
   ```
3. **全量测试**：
   ```bash
   Rscript -e 'devtools::load_all("."); testthat::test_dir("tests/testthat", reporter="summary")'
   ```
   期望：原 37 个断言 + 本轮新增全部通过，0 failures。
4. **全量 check**：
   ```bash
   Rscript -e 'devtools::check(document=FALSE, cran=FALSE, error_on="never")'
   ```
   期望：**0 errors / 0 warnings / 0 notes**。
5. **NEWS.md**：在 `# tidydr 0.0.6` 之上新增一个 dev 段落记录本轮改动
   （是否 bump `Version` 由操作方决定；**不要**擅自改 `Version`）。
6. **报告**（见第 9 节），**不要 commit / push**，除非操作方明确要求。

### 完成定义（DoD）

- [ ] R1 的 `dr(1:10, prcomp)` 现在**报错**，且有测试断言；`dist` 对象仍可用（有正向测试）
- [ ] R2 的 `nk(iris[,-5], 1)` 与 `c(2,1)` 报清晰错误，且不再产出无法打印的对象
- [ ] R3 的 matrix metadata 不再静默丢弃；`as.list(1:150)` 不再产生 154 列；`.group` 行为未变
- [ ] R4 的 `dr(as.dist(dist(iris[,1:4])), stats::cmdscale)` 返回 150x2 的 `DrResult`；
      `dr(iris[,1:4], uwot::umap)` 仍走 `dr_extract.uwot`（有测试固定）
- [ ] R5 的 `.github/workflows/R-CMD-check.yaml` 存在且 YAML 可解析
- [ ] `R CMD check` = 0/0/0；全量测试 0 failures
- [ ] 未触碰 Out of scope 清单中的任何功能项
- [ ] 未 commit / 未 push

---

## 9. 交付报告格式

每个单元报告：

```
### U? — <标题>
改动文件：<路径列表>
diff：<git diff 输出，或 --stat + 关键片段>
新增测试：<文件:行 与断言意图>
验证命令与真实输出：<粘贴原文，不要转述>
不确定/需要决策的点：<没有就写"无">
```

集成报告额外包含：全量测试汇总行、`R CMD check` 的 `Status:` 行、
以及"哪些结论未经真实环境验证"（例如 CI 未真实跑过、`vegan` 等方法未安装故未验证）。

**报告纪律**：不要把"我认为应该能跑"写成"已验证"。没有输出证据的结论一律标注为未验证。

---

## 附录 A — 一次性复现全部缺陷

```bash
cd /home/wang/data/source/tidydr
Rscript -e '
suppressMessages(devtools::load_all(".", quiet=TRUE))

cat("### R1: dr() 无输入校验\n")
print(tryCatch(dr(1:10, prcomp), error=function(e) conditionMessage(e)))   # 静默成功，10x1
print(tryCatch(dr(NULL, prcomp), error=function(e) conditionMessage(e)))

cat("\n### R2: nk(k=1) 产出无法打印的对象\n")
x <- nk(iris[,-5], 1)
print(tryCatch(print(x), error=function(e) conditionMessage(e)))

cat("\n### R3: fortify metadata\n")
d0 <- dr(iris[,1:4], prcomp)
cat("matrix -> ncol:", ncol(fortify(d0, metadata=matrix(1:300, nrow=150))), "\n")
cat("list(n) -> ncol:", ncol(fortify(d0, metadata=as.list(1:150))), "\n")

cat("\n### R4: cmdscale 实际不可用\n")
dd <- as.dist(dist(iris[,1:4]))
print(tryCatch(dr(dd, stats::cmdscale), error=function(e) conditionMessage(e)))
print(tryCatch(dr(iris[,1:4], function(d) uwot::umap(d)), error=function(e) conditionMessage(e)))
' 2>&1
```

## 附录 B — 相关源码位置索引

| 内容 | 位置 |
| --- | --- |
| `dr()` / `as.dr()` / `print.DrResult` | `R/dr.R`（`dr()` 第 16 行起） |
| `dr_extract` 泛型与各 S3 方法 | `R/method-dr-extract.R`（`default` 在文件末尾） |
| `available_methods()` 的宣称清单 | `R/available_methods.R` |
| `nk()` / `print.silinfo` / `summary.silinfo` | `R/silinfo.R` |
| `fortify.DrResult` | `R/method-fortify.R` |
| `autoplot.*` 与 `.group` 用法 | `R/method-autoplot.R`、`vignettes/tidydr.Rmd` |
| 现有测试 | `tests/testthat/`（4 个文件，37 断言） |
| 版本历史 | `NEWS.md` |
| 构建辅助 | `Makefile` |
