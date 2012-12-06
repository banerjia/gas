@select_all = null
@toolbar = null
@email_order_form = null
@order_list_form = null
@order_path = window.order_path
@email_order_path = window.email_order_path


jQuery( document ).ready () ->
	@email_order_form = jQuery( "form#email_order_form" )
	@order_list_form = jQuery( "form#order_list_form" )
	@select_all = jQuery( "input#select_all", @order_list_form )
	@toolbar = jQuery( "table#order_list thead tr.toolbar" )
	jQuery(@select_all).click select_all_toggle 
	jQuery( "input#order", @order_list_form ).click () -> 
		toggle_toolbar()
		if( !jQuery(this).is(":checked") ) 
			jQuery(select_all).attr("checked", false)
		return	

	jQuery( @toolbar ).hide()
	jQuery( "input#a_email_order", @order_list_form).leanModal
		top: 200
		overlay: 0.4
		closeButton: ".modal_close"
	return	


@toggle_toolbar = () ->
	if( jQuery("input#order", @order_list_form).filter(":checked").length > 0 )
		jQuery( @toolbar ).slideDown()
	else
		jQuery( @toolbar ).slideUp()
	return

@send_email = () ->
	ids = jQuery.map jQuery("input#order", @order_list_form )
			.filter( ":checked" ), (order) ->
				jQuery( order ).val()
		
	email = jQuery( "input#email_addresses", @email_order_form ).val()
	params_id = ids.join(",")
	jQuery.ajax
		url: @email_order_path
		data: 
			"id": params_id
			"email": email
		type: "POST"
	return

@select_all_toggle = () ->
	status = jQuery( @select_all ).is(":checked")
	jQuery( "input#order", @order_list_form ).each ( index, element ) ->
		jQuery( element ).attr("checked",status)
		return

	if( status )
		jQuery( @toolbar ).fadeIn()
	else
		jQuery( @toolbar ).fadeOut()
	return

@delete_checked_ids = () ->
	return if !confirm( 'Are you sure you want to delete the selected order(s)') 
	ids = jQuery.map jQuery("input#order", @order_list_form )
			.filter( ":checked" ), (order) ->
				jQuery( order ).val()
		
	params_id = ids.join(",")

	jQuery.ajax
		url: @order_path + '/' + params_id
		type: 'DELETE'
		success: () ->
			window.location.reload true
			return
	return	
