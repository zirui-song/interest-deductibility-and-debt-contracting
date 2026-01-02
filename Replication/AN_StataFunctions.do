*** Functions to Clean and Label Data ***

*** clean ratings
capture program drop clean_rating
program define clean_rating
	rename currentratingsymbol sp_rating
	replace sp_rating = subinstr(sp_rating, " prelim", "", .) 

	gen sp_rating_num = .
	replace sp_rating_num = 21 if sp_rating == "AAA"
	* replace sp_rating_num = 21 if sp_rating == "AA+" (only 1 obs)
	replace sp_rating_num = 20 if sp_rating == "AA" | sp_rating == "ilAA" | sp_rating == "AA+"
	replace sp_rating_num = 19 if sp_rating == "AA-"
	replace sp_rating_num = 18 if sp_rating == "A+"
	replace sp_rating_num = 17 if sp_rating == "A"
	replace sp_rating_num = 16 if sp_rating == "A-" | sp_rating == "A-1+" | sp_rating == "A-2" | sp_rating == "A-3"
	replace sp_rating_num = 15 if sp_rating == "BBB+"
	replace sp_rating_num = 14 if sp_rating == "BBB"
	replace sp_rating_num = 13 if sp_rating == "BBB-"
	replace sp_rating_num = 12 if sp_rating == "BB+"
	replace sp_rating_num = 11 if sp_rating == "BB"
	replace sp_rating_num = 10 if sp_rating == "BB-"
	replace sp_rating_num = 9  if sp_rating == "B+"
	replace sp_rating_num = 8  if sp_rating == "B"
	replace sp_rating_num = 7  if sp_rating == "B-"
	replace sp_rating_num = 6  if sp_rating == "CCC+"
	replace sp_rating_num = 5  if sp_rating == "CCC"
	replace sp_rating_num = 4  if sp_rating == "CCC-"
	replace sp_rating_num = 3  if sp_rating == "CC"
	replace sp_rating_num = 2  if sp_rating == "C"
	replace sp_rating_num = 1  if sp_rating == "D"
	replace sp_rating_num = 0 if sp_rating_num == .
	
	gen not_rated = 1 if sp_rating_num == 0
	replace not_rated = 0 if not_rated == .

	label var sp_rating_num "S\&P Rating"
	label var not_rated "Not Rated"
end

*** clean variables
capture program drop clean_variables 
program define clean_variables
	* gen logged bps
	gen log_margin_bps = log(margin_bps)
	gen log_at = log(at)
	gen log_deal_amount_converted = log(deal_amount_converted)

	local controls "log_at market_to_book ppent_by_at debt_by_at cash_by_at dividend_payer ret_vol cash_etr"
	local deal_controls "leveraged maturity log_deal_amount_converted secured_dummy tranche_type_dummy tranche_o_a_dummy sponsor_dummy"

	* generate interaction between controls and post
	foreach var in `controls' {
		gen `var'_post = `var' * post
		gen `var'_treated = `var' * treated
		gen `var'_treated_loss = `var' * treated_loss
	}
	foreach var in `deal_controls' {
		gen `var'_post = `var' * post
	}

	local controls_post "log_at_post market_to_book_post ppent_by_at_post debt_by_at_post cash_by_at_post  dividend_payer_post ret_vol_post cash_etr_post"
	local deal_controls_post "leveraged_post maturity_post log_deal_amount_converted_post secured_dummy_post tranche_type_dummy_post tranche_o_a_dummy_post sponsor_dummy_post"

	local controls_treated "log_at_treated market_to_book_treated ppent_by_at_treated debt_by_at_treated cash_by_at_treated dividend_payer_treated ret_vol_treated cash_etr_treated"
	local controls_treated_loss "log_at_treated_loss market_to_book_treated_loss ppent_by_at_treated_loss debt_by_at_treated_loss cash_by_at_treated_loss dividend_payer_treated_loss ret_vol_treated_loss cash_etr_treated_loss"

	* winsorize at 1% and 99%
	foreach var in margin_bps log_margin_bps `controls' `deal_controls' `controls_post' `controls_treated' `controls_treated_loss' {
		winsor2 `var', cuts(1 99) replace
	}
	* for each _sweep variable, replace missing to zero
	foreach var of varlist *_sweep {
		replace `var' = 0 if `var' == .
	}

	* label controls and treated, post, and treated_post
	label variable log_at "Ln(Total Assets)"
	label variable cash_flows_by_at "Cash Flows / Assets"
	label variable market_to_book "Market to Book Ratio"
	label variable ppent_by_at "PP\&E / Assets"
	label variable debt_by_at "Debt / Assets"
	label variable cash_by_at "Cash / Assets"
	label variable sales_growth "Sales Growth"
	label variable dividend_payer "Dividend Payer"
	label variable z_score "Z-Score"
	label variable nol "Net Operating Loss"
	label variable ret_buy_and_hold "Buy and Hold Return"
	label variable ret_vol "Return Volatility"
	label variable cash_etr "Cash ETR"
	label variable roa "Return on Assets"
	label variable cashflow_byat "Cash Flow / Assets"

	label variable leveraged "Leveraged"
	label variable maturity "Maturity (Years)"
	label variable deal_amount_converted "Loan Amount ($Million)"
	label variable log_deal_amount_converted "Ln(Loan Amount)"
	label variable margin_bps "Interest Spread (Basis Points)"
	label variable number_of_lead_arrangers "Number of Lead Arrangers"
	label variable secured_dummy "Secured"
	label variable tranche_type_dummy "Term Loan"
	label variable tranche_o_a_dummy "Origination"
	label variable sponsor_dummy "Sponsored"
	label variable total_asset "Assets ($Billion)"

	label variable treated "Excess Interest (30\% Rule)"
	label variable post "Post"
	label variable treated_post "Excess Interest (30\% Rule) x Post"
	label variable treated_loss "Excess Interest (Loss)"
	label variable treated_loss_post "Excess Interest (Loss) x Post"
end

capture program drop generate_treat_vars
program define generate_treat_vars
	
	gen treated_all = 1 if treated == 1 | treated_loss == 1
	replace treated_all = 0 if treated_all == .
	
	* generate continuous measures
	gen excess_interest_scaled_post = excess_interest_scaled * post

	*** quartile splits
	gen ie_excess_q4 = 1 if excess_interest_scaled > 0.89999
	gen ie_excess_q3 = 1 if inrange(excess_interest_scaled, 0.6, 0.89999)
	gen ie_excess_q2 = 1 if inrange(excess_interest_scaled, 0.300001, 0.59999)
	gen ie_excess_q1 = 1 if inrange(excess_interest_scaled, 0.00001, 0.3)

	forv i = 1/4 {
		replace ie_excess_q`i' = 0 if excess_interest_scaled == 0
		replace ie_excess_q`i' = 0 if ie_excess_q`i' == .
	}

	forv i = 1/4 {
		gen ie_excess_q`i'_post = ie_excess_q`i' * post
	}

	label var excess_interest_scaled "Excess Interest Expense (Scaled)"
	label var excess_interest_scaled_post "Excess Interest Expense (Scaled) x Post"
	label var ie_excess_q1 "Excess Interest Expense Q1"
	label var ie_excess_q2 "Excess Interest Expense Q2"
	label var ie_excess_q3 "Excess Interest Expense Q3"
	label var ie_excess_q4 "Excess Interest Expense Q4"
	label var ie_excess_q1_post "Excess Interest Expense Q1 x Post"
	label var ie_excess_q2_post "Excess Interest Expense Q2 x Post"
	label var ie_excess_q3_post "Excess Interest Expense Q3 x Post"
	label var ie_excess_q4_post "Excess Interest Expense Q4 x Post"

	local treat_cts "excess_interest_scaled excess_interest_scaled_post"
	local treat_quartiles "ie_excess_q1 ie_excess_q1_post ie_excess_q2 ie_excess_q2_post ie_excess_q3 ie_excess_q3_post ie_excess_q4 ie_excess_q4_post"
	local treat_vars "treated treated_post treated_loss treated_loss_post"	
end
