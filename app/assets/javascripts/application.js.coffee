# This is a manifest file that'll be compiled into including all the files listed below.
# Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
# be included in the compiled file accessible from http://example.com/assets/application.js
# It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
# the compiled file.
#
# require jquery
# require jquery_ujs

String.prototype.toTitleCase=() ->
	this.replace /\w\S*/g, (txt) ->
		txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase()



@closeButton = () ->
	if URL != null && URL.return_path.length > 0 
		window.location = URL.return_path
	else
		history.go(-1)

	return

