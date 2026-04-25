********************************************************************************
* 上市公司资本结构分析 - 基准回归与分组回归
* M1: TWFE基准模型
* M1': 交互固定效应模型(IFE)
* M2: 分组回归（SOE vs 非SOE）
* M3: 交互项调节效应
********************************************************************************

clear all
set more off
cap log close

* 设置工作目录
cd "C:\Users\29248\Desktop\dsfin\PYC-ex_P03\data\clean"

* 打开日志
log using "..\..\output\regression_m1_m3.log", replace

* 读取数据
use panel_data.dta, clear

* 将stkcd从字符串转为数值
destring stkcd, gen(stkcd_num) force
drop stkcd
rename stkcd_num stkcd

* 描述数据
describe
summarize

* 设定面板结构
xtset stkcd year
xtdescribe

********************************************************************************
* M1: 双向固定效应基准模型（TWFE）
********************************************************************************
di "================================================================================"
di "M1: 双向固定效应基准模型（TWFE）"
di "================================================================================"

reghdfe lev npr size tang growth ndts, ///
    absorb(stkcd year) ///
    vce(cluster stkcd year)

est store m1

* 呈现结果（带格式）
display ""
display "M1: TWFE 基准回归结果"
display "因变量: Lev (杠杆率)"
display "核心解释变量: NPR (盈利能力)"
display ""
display "标准误：双向聚类（公司层面和年度层面）"
display ""

* 保存结果
estimates table m1, b(%6.4f) se(%6.4f)

********************************************************************************
* M1': 交互固定效应模型（IFE）—— 稳健性检验
********************************************************************************
di "================================================================================"
di "M1': 交互固定效应模型（IFE）"
di "================================================================================"

* 计算交互固定效应（控制宏观因素的异质性影响）
* 同时加入m2_growth作为可观测的宏观控制变量

reghdfe lev npr size tang growth ndts m2_growth, ///
    absorb(stkcd year#m2_growth) ///
    vce(robust)

est store m1_ife

display ""
display "M1': IFE 回归结果"
display ""

* 对比M1和M1'
estimates table m1 m1_ife, b(%6.4f) se(%6.4f) 
* 检验m2_growth的系数
test m2_growth

********************************************************************************
* M2: 分组回归（按SOE分组）
********************************************************************************
di "================================================================================"
di "M2: 分组回归（SOE vs 非SOE）"
di "================================================================================"

* 国有企业
reghdfe lev npr size tang growth ndts if soe==1, ///
    absorb(stkcd year) ///
    vce(cluster stkcd year)
est store m2_soe

display ""
display "M2a: 国有企业（SOE=1）"
display ""

* 民营企业
reghdfe lev npr size tang growth ndts if soe==0, ///
    absorb(stkcd year) ///
    vce(cluster stkcd year)
est store m2_private

display ""
display "M2b: 民营企业（SOE=0）"
display ""

* 合并结果
estimates table m2_soe m2_private, b(%6.4f) se(%6.4f)

********************************************************************************
* M3: 交互项调节效应
********************************************************************************
di "================================================================================"
di "M3: 交互项调节效应"
di "================================================================================"

* 生成交互项
gen npr_soe = npr * soe

reghdfe lev npr npr_soe size tang growth ndts, ///
    absorb(stkcd year) ///
    vce(cluster stkcd year)
est store m3

display ""
display "M3: 交互项调节效应"
display "NPR系数（民营企业）: 直接效应"
display "NPR + NPR×SOE系数（国有企业）: 国有企业中NPR的效应"
display ""

* 呈现结果
estimates table m1 m2_soe m2_private m3, b(%6.4f) se(%6.4f)

********************************************************************************
* 回归结果汇总表
********************************************************************************
di "================================================================================"
di "回归结果汇总表（M1-M3）"
di "================================================================================"

#delimit ;
esttab m1 m1_ife m2_soe m2_private m3
    using "..\..\output\regression_results_m1_m3.csv",
    replace
    csv
    b(%6.4f)
    se(%6.4f)
        keep(npr npr_soe m2_growth size tang growth ndts)
    order(npr npr_soe m2_growth size tang growth ndts)
    nodepvars
    noobs
    nonumbers
    ;

#delimit cr

display ""
display "回归结果已保存至 output/regression_results_m1_m3.csv"

* 同时保存为 regression_results.csv（供notebook使用）
#delimit ;
esttab m1 m1_ife m2_soe m2_private m3
    using "..\..\output\regression_results.csv",
    replace
    csv
    b(%6.4f)
    se(%6.4f)
        keep(npr npr_soe m2_growth size tang growth ndts)
    order(npr npr_soe m2_growth size tang growth ndts)
    nodepvars
    noobs
    nonumbers
    ;

#delimit cr

display "回归结果已保存至 output/regression_results.csv"

log close