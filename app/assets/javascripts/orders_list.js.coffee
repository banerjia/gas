class @OrderList
    @init : () ->
        window.select_all = null
        window.toolbar = null
        window.email_order_form = null
        window.order_list_form = null
        # Grabbing certain objects that will be repeatedly used throughout
        # the page. Doing so will reduce the number of time jQuery.find
        # function is invoked. 
        window.email_order_form = jQuery( "form#email_order_form" )
        window.order_list_form = jQuery( "form#order_list_form" )
        window.select_all = jQuery( "input#select_all", window.order_list_form )
        window.toolbar = jQuery( "table#order_list thead tr.toolbar" )

        # Binding events handlers to objects
        jQuery(window.select_all).click OrderList.select_all_toggle
        jQuery( "input#send_email", window.email_order_form ).bind "click", OrderList.send_email
        jQuery( "input#delete_orders", window.toolbar ).bind "click", OrderList.delete_checked_ids
        OrderList.bind_click_event_for_checkboxes()

        # Initializing the state of certain objects
        jQuery( window.toolbar ).hide()
        jQuery( "input#a_email_order", window.order_list_form).leanModal
           top: 200
           overlay: 0.4
           closeButton: ".modal_close"
        return
        
    @toggle_toolbar : () ->
       if( jQuery("input#order", window.order_list_form).filter(":checked").length > 0 )
          jQuery( window.toolbar ).slideDown()
       else
          jQuery( window.toolbar ).slideUp()
       return

    @send_email : () ->
       ids = jQuery.map jQuery("input#order", window.order_list_form )
             .filter( ":checked" ), (order) ->
                jQuery( order ).val()
      
       email = jQuery( "input#email_addresses", window.email_order_form ).val()
       email_body =  jQuery( "textarea#email_body", window.email_order_form ).val().trim()
       params_id = ids.join(",")
       jQuery.ajax
          url: window.email_order_path
          beforeSend: (xhr) ->
                           xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))
                           return
          data:
             "id": params_id
             "email": email
             "email_body":  email_body if email_body
          type: "POST"
       jQuery(".modal_close" ).trigger("click")
       return

    @select_all_toggle : () ->
       status = jQuery( window.select_all ).is(":checked")
       jQuery( "input#order",jQuery( window.order_list_form) ).each ( index, element ) ->
          jQuery( element ).attr("checked",status)
          return

       if( status )
          jQuery( window.toolbar ).fadeIn(800)
       else
          jQuery( window.toolbar ).hide()
       return

    @delete_checked_ids : () ->
       return if !confirm( 'Are you sure you want to delete the selected order(s)')
       ids = jQuery.map jQuery("input#order", window.order_list_form )
             .filter( ":checked" ), (order) ->
                jQuery( order ).val()
      
       params_id = ids.join(",")
       window.location.reload(true)
       jQuery.ajax
          url: window.order_path + '/' + params_id
          beforeSend: (xhr) ->
                           xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))
                           return
          data:
             "id": params_id
             "email": email
             "email_body":  email_body if email_body
          type: "POST"
          
          type: 'POST'
          data:
             "_method": 'delete'
          success: () ->
             window.location.reload(true)
             return
       return
    
    @bind_click_event_for_checkboxes : () ->
      jQuery( "input#order", window.order_list_form ).bind "click", () ->
         OrderList.toggle_toolbar()
         if( !jQuery(this).is(":checked") )
            jQuery(select_all).attr("checked", false)
         return
      return
