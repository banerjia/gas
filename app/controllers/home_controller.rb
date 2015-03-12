class HomeController < ApplicationController

	def index
		@page_title = nil
		@browser_title = "Home"

		@recent_orders = Order.search({start_date: 1.week.ago, end_date: Date.today, page: 1, per_page: 5, sort: "created_at-desc" })[:results]

		@recent_audits = Audit.search({start_date: 2.weeks.ago, end_date: Date.today, page: 1, per_page: 5, sort: "created_at-desc" })

		session.delete(:last_page)

	end

end