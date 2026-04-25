********************************************************************************
* 上市公司资本结构分析 - 时变系数模型
* M4: 时变系数模型（允许NPR系数随年份变化）
********************************************************************************

clear all
set more off
cap log close

* 设置工作目录
cd "C:\Users\29248\Desktop\dsfin\PYC-ex_P03\data\clean"

* 打开日志
log using "../../output/regression_m4.log", replace

* 读取数据
use panel_data.dta, clear

* 将stkcd从字符串转为数值
destring stkcd, gen(stkcd_num) force
drop stkcd
rename stkcd_num stkcd

* 设定面板结构
xtset stkcd year

********************************************************************************
* M4: 时变系数模型
* 通过NPR与年份虚拟变量的交互项来估计各年的系数
********************************************************************************
di "================================================================================"
di "M4: 时变系数模型"
di "================================================================================"

* 时变系数模型：NPR与年份的交互
* 注意：year不能同时被absorb，否则i.year#c.npr没有变异
* 所以这里只absorb stkcd，year用虚拟变量显式控制
reghdfe lev i.year c.npr i.year#c.npr size tang growth ndts, ///
    absorb(stkcd) ///
    vce(cluster stkcd year)

est store m4

display ""
display "M4: 时变系数模型"
display "交互项 i.year#c.npr 表示允许NPR的效应在各年不同"
display ""

********************************************************************************
* 绘制时变系数图（带置信区间）
********************************************************************************
di "================================================================================"
di "绘制 β_t 时序图"
di "================================================================================"

* 提取交互项系数和标准误
matrix b = e(b)
matrix V = e(V)

* 创建系数图数据
postutil clear
postfile bt year coef se ci_low ci_high using "..\..\output\beta_time_coef.dta", replace

forvalues y = 2010/2025 {
    local idx = `y' - 2009  // 2010->1, 2011->2, ..., 2025->16
    local coef_idx = 17 + `idx'  // 交互项在b矩阵中的位置

    scalar coef_val = b[1, `coef_idx']
    scalar se_val = sqrt(V[`coef_idx', `coef_idx'])
    scalar ci_l = coef_val - 1.96 * se_val
    scalar ci_h = coef_val + 1.96 * se_val

    post bt (`y') (coef_val) (se_val) (ci_l) (ci_h)
}

postclose bt

* 保存为CSV（供Python notebook使用）
use "..\..\output\beta_time_coef.dta", clear
outsheet using "..\..\output\beta_time_coef.csv", replace comma

* 绘制图形（Stata原生绘图）
use "..\..\output\beta_time_coef.dta", clear

twoway (rarea ci_low ci_high year, fcolor(gs12) lcolor(gs12)) ///
       (line coef year, lcolor(blue) lwidth(medium) mlabel(coef) msymbol(circle)), ///
       yline(0, lcolor(red) lpattern(dash)) ///
       title("Fig 5: Time-Varying β of NPR on Leverage (M4)") ///
       xtitle("Year") ///
       ytitle("Marginal Effect of NPR (β)") ///
       legend(off) ///
       name(beta_time) ///
       graphregion(fcolor(white))

graph export "..\..\output\figures\Fig5_beta_time.png", as(png) replace

di "时变系数图已保存至 output/figures/Fig5_beta_time.png"

log close