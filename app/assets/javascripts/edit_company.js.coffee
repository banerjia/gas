@division_errors = -> 
	division_names = new Array()
	division_name_fields = jQuery("input[id^=company_divisions_attributes]:text")
	division_name_fields.each () -> 
		division_name = jQuery(this).val().toUpperCase()
		last_index_of = division_names.indexOf( division_name )
		if last_index_of > -1
			jQuery(division_name_fields[last_index_of]).removeClass("error_field").addClass("error_field")
			jQuery(this).addClass("error_field")
		else
			division_names.push division_name.toUpperCase()

			