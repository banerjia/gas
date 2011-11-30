
	// Note: A lot of the JS code relies on naming conventions.
	// For variables, objects or HTML elements related to state have the word "state",
	// in singular or plural form, as a distinct part of the name/id. Eg. obj_state, 
	// li_state, state_listing, states_array. Apply the same for division information
	// as well. Quite a few functions use the parameter "type_of_listing", which contains
	// either "state" or "division". Based on this parameter, other variable or element
	// names are deduced. 

	// Variables
	// --------------
	// current_section - holds information about which nav item is currently displayed
	// jData.states, jData.divisions - contain the data retrieved from calls to 
	//					thier respective web services. Storing this information
	//					in local variable eliminates the need to call these services
	//					when switching back and forth between the different sections of
	//					the page.
	//	state_listing, division_listing - jQuery objects to the two different tables for 
	//					listing state and division store information. These variables
	//					are set in the document.ready event handler to avoid repeated
	//					jQuery searches on the DOM for these sections.
	// ajax_message_container, ajax_message - jQuery objects to the HTML elements that
	//					are used to present AJAX error messages to the user interface.
	// jqAjaxRequest - the request object returned from a jQuery.ajax call. The main purpose
	//					of this variable is to provide a way to abort an AJAX call. For
	//					example, if the user first clicks on the state listing and then 
	//					immediately clicks the division listing, the first AJAX call should
	//					be cancelled to avoid any client side scripting errors or call-
	//					overlaps. 
	var current_section;
	var state_listing;
	var division_listing;
	var jData = new Object();
	jData.states = null;
	jData.divisions = null;
	var jData_states = null;
	var jData_divisions = null;
	var ajax_message_container = null;
	var ajax_message = null;
	var jqAjaxRequest = null;
	
	
	// Function to convert any string to propercase
	function toTitleCase(str)
	{
	    return str.replace(/\w\S*/g, function(txt){return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();});
	}


	// Function to facilitate switching sections based on the nav item selected. 
	function switch_sections( target_section ){	
		if(jQuery(target_section).attr("class") == "no-section-change") return;		
		var previous_section = jQuery(current_section).attr("id");
		var next_section = jQuery(target_section).attr("id");
		jQuery(current_section).removeClass("current");
		// Condition to avoid conflicts with showing the loading animation. Basically the logic is that 
		// if the target li tag has the "loading" class attached to it then don't add the "current"
		// class to it. A list block item can only have one background-image.
		var liLoading = jQuery("li.loading");
		if( liLoading == null || liLoading.attr("id") != jQuery(target_section).attr("id") )
			jQuery(target_section).addClass("current");
		
		current_section = jQuery(target_section);
	
		previous_section = previous_section.substring( 0,previous_section.indexOf("_")) + "#" +
						   previous_section.substring( previous_section.indexOf("_") + 1);
		next_section = next_section.substring( 0, next_section.indexOf("_")) + "#" +
					   next_section.substring(next_section.indexOf("_")+1);
		jQuery(previous_section).hide();
		jQuery(next_section).show();
	
	}
	
	// Generic function to populate listing
	function populate_listing( data_array, target_table, type_of_listing){
		var number_of_items = data_array.length;
		var link_prefix = null;
		
		// Deducing the link URL prefix to use based on the 
		// type_of_listing parameter and the naming convention
		// used for link_prefix defined in show.html.erb
		eval("link_prefix = link_prefix_" + type_of_listing);
		
		for( var iIterator = 0; iIterator < number_of_items; iIterator++ ){
			// Creating a table row
			var table_row = jQuery("<tr/>");
			
			// Logic for alternate row
			// To be used for non HTML5 browsers
			if(iIterator%2 != 0) table_row.addClass("alternate");
			
			// Generate link for list of stores in a state
			// The following lines will result in the HTML code:
			// <a href="/graeters/companies/999/stores/<state acronym>"> <number of stores> </a>
			// Or
			// <a href="/graeters/companies/999/divisions/999/stores"> <number of stores> </a>
			
			var column_stores_link = jQuery("<td/>");
			var aTag_stores = jQuery("<a/>");
			
			// The following line produces a link string: /graeters/companies/<999>/stores/US-OH
			var first_column_data = null;
			switch(type_of_listing){
				case "state":
					link = link_prefix + "/" + data_array[iIterator].country + "-" + data_array[iIterator].state_code;
					first_column_data = data_array[iIterator].state_name;
					break;
				case "division":
					link = link_prefix + "/" + data_array[iIterator].id + "/stores";
					first_column_data = data_array[iIterator].name;
					break;						
			}
			
			aTag_stores.attr("href", link);
			aTag_stores.html(data_array[iIterator].stores_count);
			
			// Adding the link tag to the column
			column_stores_link.append(aTag_stores);
			
			// Adding the columns to the table row
			// First .append - State Name
			// Second .append - link to stores
			 
			table_row
				.append(
					jQuery("<td/>").html(first_column_data)
				)
				.append(column_stores_link);

			// Appending the table row to the table
			target_table.append( table_row );
		}
	}

	function get_listing(targetLI, type_of_listing){
		// Generic objects
		var ajax_data = null;
		var loading_container = null;
		var ajax_link = null;
		
		if(typeof targetLI == "string") targetLI = jQuery("li#" + targetLI);
		
		// Populating generic objects with appropriate information
		// Note: naming conventions play a major role in reducing
		// "if" and "switch" blocks
		eval( "ajax_data = jData." + type_of_listing + "s");
		eval( "loading_container = " + type_of_listing + "_listing");
		eval( "ajax_link = ajax_link_" + type_of_listing + "s");
		
		// Check if data was already downloaded
		if(ajax_data == null){
			var liItem = jQuery(targetLI);
			
			// If there is a pending AJAX request - abort it
			if( jqAjaxRequest != null){
				jqAjaxRequest.abort();
				jqAjaxRequest = null;
			}
			
			// Display loading animation for the list item 
			// originating this request
			liItem.addClass("loading");
			
			if(jQuery(ajax_message_container).is(":visible"))
				jQuery(ajax_message_container).hide();
			
			// Make the request
			jqAjaxRequest = jQuery.ajax({
				url: ajax_link,
				dataType: 'json',
				success: function(data){
					jqAjaxRequest = null; // clearing the request flag
					// Using naming conventions to get the right data array
					// Type of Listing		Expected data array
					// -----------------------------------------
					// state				data.states
					// division				data.divisions
					eval("ajax_data = data." + type_of_listing + "s");
					eval("listing_container = " + type_of_listing + "_listing");
					populate_listing(ajax_data, listing_container, type_of_listing);
					jQuery("li.loading").removeClass("loading").addClass("current");
					eval("jData." + type_of_listing +"s = ajax_data");									
				},
				error: function(data){
					jqAjaxRequest = null;
					ajax_data = null;
					var error_message = "It appears that the requested information is currently unavailable. ";
					error_message += 'Please <a onclick="get_listing(\'' + jQuery(targetLI).attr("id") + '\',\'' + type_of_listing +'\')">retry</a>.';
					update_ajax_message(error_message, "ajax_issue");
					jQuery("li.loading").removeClass("loading").addClass("current");
					eval("jData." + type_of_listing +"s = ajax_data");
				}
			});					
		}			
	}
	
	function update_ajax_message(message, message_type){
		// function to update the ajax message div
		// in case there was a problem retrieving
		// information from the web service
		jQuery(ajax_message).html(message);
		jQuery(ajax_message_container).addClass(message_type).show();
	}