# Generic function to change the case of text from lower/upper-case to propercase.
@toTitleCase = (input_text) ->
	input_text.replace /\w\S*/g, (text) ->
		text.charAt(0).toUpperCase() + text.substr(1).toLowerCase()

# Generic function to switch back and forth between the different sections of the page
@switch_sections = ( target_section )->
	# This is patch to prevent a Javascript error when there is no
	# section associated with a list item. List items that contain
	# links to other pages will be handled by this line. 
	return 0 if jQuery(target_section).attr("class") == "no-section-change"
	
	previous_section = jQuery(@current_section).attr("id")
	next_section = jQuery(target_section).attr("id")
	jQuery(@current_section).removeClass("current")
	# Condition to avoid conflicts with showing the loading animation. Basically the logic is that
	# if the target li tag has the "loading" class attached to it then don't add the "current"
	# class to it. A list block item can only have one background-image.
	liLoading = jQuery("li.loading")
	if liLoading == null || liLoading.attr("id") != jQuery(target_section).attr("id") 
		jQuery(target_section).addClass("current")

	@current_section = jQuery(target_section)

	previous_section = previous_section.substring( 0,previous_section.indexOf("_")) + "#" +	previous_section.substring( previous_section.indexOf("_") + 1)
	next_section = next_section.substring( 0, next_section.indexOf("_")) + "#" + next_section.substring(next_section.indexOf("_") + 1)

	jQuery(previous_section).hide()
	jQuery(next_section).show()


# Generic function to populate listing
@populate_listing= ( data_array, target_table, type_of_listing) ->
	
	number_of_items = data_array.length
	link_prefix = null

	# Deducing the link URL prefix to use based on the
	# type_of_listing parameter and the naming convention
	# used for link_prefix defined in show.html.erb
	eval "link_prefix = link_prefix_" + type_of_listing
	
	for iIterator in [0..(number_of_items - 1)]
		# Creating a table row
		table_row = jQuery("<tr/>")

		# Logic for alternate row
		# To be used for non HTML5 browsers
		table_row.addClass("alternate") if iIterator%2 != 0 		

		stores_link_column = jQuery("<td/>")
		aTag_stores = jQuery("<a/>")
		
		# Generate link for list of stores in a state
		# The following lines will result in the HTML code:
		# <a href="/graeters/companies/999/stores/<state acronym>"> <number of stores> </a>
		# Or
		# <a href="/graeters/companies/999/divisions/999/stores"> <number of stores> </a>

		
		first_column_data = null
		switch type_of_listing
			when "state"
				# Link produced: /graeters/companies/<999>/stores/US-OH
				link = link_prefix + "/" + data_array[iIterator].country + "-" + data_array[iIterator].state_code
				first_column_data = data_array[iIterator].state_name
				
			when "division"
				# Link produced: /graeters/companies/999/divisions/999/stores
				link = link_prefix + "/" + data_array[iIterator].id + "/stores"
				first_column_data = data_array[iIterator].name

		aTag_stores.attr("href", link)
		aTag_stores.html(data_array[iIterator].stores_count)

		# Adding the link tag to the column
		stores_link_column.append(aTag_stores)

		# Adding the columns to the table row
		# First .append - State Name
		# Second .append - link to stores

		table_row
			.append(
				jQuery("<td/>").html(first_column_data)
			)
			.append(stores_link_column)

		# Appending the table row to the table
		target_table.append( table_row )