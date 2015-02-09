class HomeController < ApplicationController

	def index
		@page_title = nil
		@browser_title = "Home"

		# @recent_orders = Order.includes([:store, :route]).where({created_at: [2.days.ago..DateTime.now]}).order({created_at: :desc}).limit(5)
		@recent_orders = Order.search({start_date: 2.days.ago, end_date: Date.today, page: 1, per_page: 5, sort: "created_at-desc" })[:results]

		# @recent_audits = Audit.includes(:store).where({created_at: [2.weeks.ago..DateTime.now]}).order({created_at: :desc}).limit(5)
		@recent_audits = Audit.search({start_date: 2.weeks.ago, end_date: Date.today, page: 1, per_page: 5, sort: "created_at-desc" })

	end

end