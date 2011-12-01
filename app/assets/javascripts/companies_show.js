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
	

	// Function to facilitate switching sections based on the nav item selected. 

	
	// Generic function to populate listing


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
/*	
	function update_ajax_message(message, message_type){
		// function to update the ajax message div
		// in case there was a problem retrieving
		// information from the web service
		jQuery(ajax_message).html(message);
		jQuery(ajax_message_container).addClass(message_type).show();
	}
*/