namespace :dev_env_load do
	task refresh_es: :environment do
		Store.index_refresh
		Order.index_refresh
		Audit.index_refresh
	end
end
