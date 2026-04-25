# 上市公司资本结构影响因素分析

> [作业要求](https://github.com/lianxhcn/dsfin/blob/main/homework/ex_P03_Panel-capital_strucuture.md)

## 个人信息

- 姓名：彭远超
- 邮箱：yuanchao29zoe@163.com

### 数据来源
- CSMAR，下载时间：2026年4月23日
- 最终样本：4,046 家公司，34,765 个观测值，2010-2025年

### 样本筛选流程

| 筛选步骤 | 剔除观测数 | 剩余观测数 | 剩余公司数 |
|---------|----------|----------|----------|
| 初始样本 | — | 49,911 | 5,240 |
| 剔除金融保险（J类） | 867 | 49,044 | 5,175 |
| 剔除 Lev > 1（资不抵债） | 1,222 | 48,689 | 5,174 |
| 剔除缺失值 | 5,129 | 43,560 | 5,052 |
| 剔除 ST/PT（曾被ST即全年度剔除） | 8,480 | 35,080 | 4,303 |
| 剔除行业代码 Unknown | 315 | 34,765 | 4,046 |
| **最终样本** | — | **34,765** | **4,046** |

### 工具
- Stata 18.0 MP（主要建模）/ Python 3.11（数据处理与画图）
- Jupyter Notebook
- 环境：`dsfin_py311` (conda)

### GitHub 仓库
https://github.com/PYC1234/dshw--panel

### Quarto Book（如完成）
https://PYC1234.github.io/dshw--panel/

### 主要发现

1. **NPR与Lev负相关，支持优序融资理论**。M1基准回归 NPR 系数为 −0.627（p<0.001），盈利增强→内源融资上升→杠杆率显著下降。

2. **国有企业与民营企业存在显著差异**。国企 NPR 系数 −0.839，民企 −0.511，差异约64%。M3 交互项 NPR×SOE = −0.196（p<0.05），SOE 强化了负向效应。

3. **NPR−Lev关系在2015年前后出现结构性变化**。M4时变系数：2015-2016年负效应最强（去杠杆政策初期），此后逐年减弱，与去杠杆政策周期吻合。

4. **企业规模对NPR−Lev关系有显著的调节与门槛效应**。M5函数系数：小型企业 |β| = 0.83，大型企业 |β| = 0.40。M6门槛值 γ ≈ 22.13（约4.1亿元总资产），规模>门槛的 NPR 负效应显著更弱。

5. **IFE与TWFE对比结果稳健**。M1' 控制宏观冲击异质性后，NPR 系数保持 −0.627，基准回归对未观测的时变异质性稳健。

---

## 项目结构

```
dshw--panel/
├── data/
│   ├── raw/                    # 原始CSMAR数据（不上传GitHub）
│   └── clean/                  # 清洗后数据
│       ├── panel_data.csv      # 清洗后面板数据 (34,765 obs)
│       └── panel_data.dta      # Stata格式面板数据
├── output/
│   ├── figures/                # Fig 1-7 输出图形
│   │   ├── Fig1_lev_npr_trend.png
│   │   ├── Fig2_winsorize_comparison.png
│   │   ├── Fig3_correlation_heatmap.png
│   │   ├── Fig3_lev_yearly_boxplot.png
│   │   ├── Fig4_soe_moderation.png
│   │   ├── Fig5_beta_time.png
│   │   ├── Fig6_beta_size_poly.png
│   │   └── Fig7_threshold_lr.png
│   ├── screening_table.csv     # 样本筛选记录
│   ├── desc_stats_*.csv        # 描述性统计
│   ├── ttest_soe_results.csv   # SOE vs 民营 t检验
│   ├── correlation_matrix.csv  # 相关系数矩阵
│   ├── regression_results.csv  # M1-M3 回归结果
│   ├── regression_summary_m1_m6.csv  # M1-M6 汇总表
│   ├── beta_time_coef.csv      # M4 时变系数
│   ├── beta_size_coef.csv      # M5 函数系数
│   └── threshold_lr.csv        # M6 门槛LR曲线
├── do/                         # Stata do文件
│   ├── 01_baseline_regression.do   # M1, M1', M2, M3
│   ├── 02_timevarying_coef.do      # M4
│   └── 03_functional_coef.do       # M5, M6
├── 01_data_processing.ipynb       # 数据处理
├── 02_descriptive_stats.ipynb     # 描述性统计
├── 03_results_and_figures.ipynb   # 结果汇总 + 讨论问题
├── 04_stata_regression.ipynb      # nbstata 运行 Stata（可选）
├── README.md
└── .gitignore
```

---

## 运行说明

### 1. 环境配置

```bash
conda activate dsfin_py311
```

### 2. 数据准备

1. 登录 CSMAR 下载以下数据表（2010-2025年度）：
   - 资产负债表 → `balance_sheet.csv`
   - 利润表 → `income_stmt.csv`
   - 现金流量表 → `cashflow.csv`
   - 股权性质 → `ownership.csv`
   - 行业分类 → `industry.csv`
   - ST/PT标记 → `st_flag.csv`
   - M2增长率 → `m2.csv`

2. 将数据文件放入 `data/raw/` 目录

### 3. 运行分析

**Python Notebook（数据处理 + 描述统计 + 图形 + 讨论）**

```bash
jupyter notebook
# 依次运行 01_data_processing.ipynb → 02_descriptive_stats.ipynb → 03_results_and_figures.ipynb
```

**Stata（回归分析）**

```stata
cd "C:\Users\29248\Desktop\dsfin\PYC-ex_P03\data\clean"
do "../do/01_baseline_regression.do"    // M1, M1', M2, M3
do "../do/02_timevarying_coef.do"       // M4
do "../do/03_functional_coef.do"        // M5, M6
```

**或者使用 nbstata（Jupyter 中直接运行 Stata）**

```bash
jupyter notebook
# 运行 04_stata_regression.ipynb
```

---

## 核心结论

### 理论检验结论
支持**优序融资理论**（Pecking Order Theory）。M1 基准回归显示 NPR 系数 = −0.627（p<0.001），盈利能力增强→内源融资上升→企业减少对外部债务的依赖，杠杆率下降。控制变量 Size、Tang、Growth、NDTS 方向与理论预期一致。

### SOE调节效应
**产权性质显著调节 NPR−Lev 关系**。国企 NPR 系数（−0.839）强于民企（−0.511），差异约64%。M3 交互项 NPR×SOE = −0.196（p<0.05）。预算软约束理论解释：国企面临隐性担保和偏高债务成本，盈利改善时偿债意愿更强；民企受融资约束制约，盈利更多用于投资扩张。

### 时变特征
**2015-2016年 β_t 最负**（去杠杆政策初期），此后负效应逐年减弱。M4 时变系数图显示 β_t 在 2015 年附近达到最低点，与"去杠杆"政策周期高度吻合。COVID-19（2020）期间负效应短暂加剧，随后继续减弱。

### 信息不对称机制
**企业规模对 NPR−Lev 关系存在显著的门槛效应**。M5 函数系数 β(Size) = −32.075 + 2.853×Size − 0.0645×Size²，边际效应随规模增大而衰减（|β|：0.83 → 0.40）。M6 门槛值 γ ≈ 22.13（约4.1亿元总资产），规模 > 门槛的企业 NPR 效应显著更弱。小企业信息不对称严重→依赖内源融资→NPR−Lev 联动强；大企业融资渠道多元→NPR 效应被稀释。

---

## 参考资料

- [作业要求原文](https://github.com/lianxhcn/dsfin/blob/main/homework/ex_P03_Panel-capital_strucuture.md)
- [Quarto Book 教程](https://lianxhcn.github.io/quarto_book/)
- [Stata 环境配置](https://lianxhcn.github.io/dsfin/Lecture/00-setup/01_01_install_anaconda.html)
