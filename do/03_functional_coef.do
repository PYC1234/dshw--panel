********************************************************************************
* 上市公司资本结构分析 - 函数系数模型与门槛模型
* M5: 函数系数模型（多项式调节）
* M6: 门槛模型
********************************************************************************

clear all
set more off
cap log close

* 设置工作目录
cd "C:\Users\29248\Desktop\dsfin\PYC-ex_P03\data\clean"

* 打开日志
log using "..\..\output\regression_m5_m6.log", replace

* 读取数据
use panel_data.dta, clear

* 将stkcd从字符串转为数值
destring stkcd, gen(stkcd_num) force
drop stkcd
rename stkcd_num stkcd

* 设定面板结构
xtset stkcd year

********************************************************************************
* M5: 函数系数模型（多项式调节）
* 允许NPR的效应随企业规模（Size）变化
********************************************************************************
di "================================================================================"
di "M5: 函数系数模型（多项式调节）"
di "================================================================================"

* 生成高阶交互项
gen npr_size = npr * size
gen npr_size2 = npr * size^2

* 多项式调节回归
reghdfe lev npr npr_size npr_size2 size tang growth ndts, ///
    absorb(stkcd year) ///
    vce(cluster stkcd year)

est store m5_poly

display ""
display "M5: 函数系数模型（多项式调节）"
display "β(Size) = β0 + β1*Size + β2*Size^2"
display ""

* 呈现结果
estimates table m5_poly, b(%6.4f) se(%6.4f)

* 计算边际效应并绘图
* 由于reghdfe吸收了高维固定效应，用coefplot更可靠
reghdfe lev c.npr c.npr#c.size c.npr#c.size#c.size size tang growth ndts, ///
    absorb(stkcd year) ///
    vce(cluster stkcd year)

* 用coefplot展示npr的边际效应随size的变化
 margins, at(size=(20(0.5)30))
 marginsplot, ///
    name(beta_size_poly) ///
    title("β(Size): Marginal Effect of NPR on Leverage") ///
    xtitle("Size (ln Total Assets)") ///
    ytitle("β(Size)") ///
    yline(0, lcolor(red) lpattern(dash)) ///
    graphregion(fcolor(white))

graph export "..\..\output\figures\Fig6_beta_size_poly.png", as(png) replace

di "多项式调节系数图已保存至 output/figures/Fig6_beta_size_poly.png"

********************************************************************************
* 保存β(Size)系数为CSV
********************************************************************************
di "================================================================================"
di "保存β(Size)系数"
di "================================================================================"

* 使用postfile保存margins结果
postfile betasize siz val se ci_l ci_h using "..\..\output\beta_size_coef.dta", replace

forvalues s = 20(0.5)30 {
    quietly margins, dydx(npr) at(size=(`s'))
    matrix b = r(b)
    matrix V = r(V)
    scalar v = b[1,1]
    scalar vv = sqrt(V[1,1])
    post betasize (`s') (v) (vv) (v - 1.96*vv) (v + 1.96*vv)
}

postclose betasize

* 转换为CSV供Python使用
use "..\..\output\beta_size_coef.dta", clear
outsheet using "..\..\output\beta_size_coef.csv", replace comma

di "β(Size)系数已保存至 output/beta_size_coef.csv"

********************************************************************************
* M6: 门槛模型
* 使用Hansen(1999)面板门槛模型
********************************************************************************
di "================================================================================"
di "M6: 门槛模型"
di "================================================================================"

* 重新加载原始数据用于门槛估计
use panel_data.dta, clear
destring stkcd, gen(stkcd_num) force
drop stkcd
rename stkcd_num stkcd

* 设置面板（不需要xtbalance，xthreg会自动处理）
xtset stkcd year

di "面板设定完成"

* 单门槛检验
di "单门槛检验..."
xthreg lev npr size tang growth ndts, ///
    rx(npr) ///
    thv(size) ///
    trim(0.05) ///
    nboot(300) ///
    id(stkcd) ///
    time(year)

scalar thresh_single = e(thrs_1)
di ""
di "单门槛值: " thresh_single
di "对应规模约为: " exp(thresh_single) " 亿元（总资产）"

* 获取门槛估计值和标准误
scalar gamma_hat = thresh_single
scalar se_gamma = e(se_1)

* 手动构造LR曲线：LR(gamma) = -2*ln[(L_max - L_gamma)/L_max]
* 近似方法：利用N(0,1)分布性质
* 更直接：用正态分布近似，似然比统计量在gamma附近呈卡方分布
* 这里用Hansen(1999)的近似：LR(gamma) = [gamma - gamma_hat]' * I(gamma_hat)' * [gamma - gamma_hat]

* 生成size网格（用样本内的size范围）
summarize size, detail
local size_min = r(min)
local size_max = r(max)
local step = (`size_max' - `size_min') / 200

postfile threshold size_grid lr_stat threshold_hat using "..\..\output\threshold_lr.dta", replace

forvalues g = 1/201 {
    scalar g_val = `size_min' + (`g'-1) * `step'
    * LR统计量近似（基于正态分布得分）：
    * 在gamma_hat附近，LR ~ chi2(1)，但这里用距离度量
    scalar dist = abs(g_val - gamma_hat)
    scalar lr_val = dist * sqrt(e(N_1))  * 2  // 简化近似
    * 实际LR应从似然函数计算，这里用距离函数近似
    scalar lr_approx = (dist / se_gamma)^2
    post threshold (g_val) (lr_approx) (gamma_hat)
}

postclose threshold

use "..\..\output\threshold_lr.dta", clear
outsheet using "..\..\output\threshold_lr.csv", replace comma

di "门槛LR曲线已保存至 output/threshold_lr.csv"

* 重新加载beta_size_coef数据（恢复之前状态）
use "..\..\output\beta_size_coef.dta", clear

di "门槛模型估计完成"

log close