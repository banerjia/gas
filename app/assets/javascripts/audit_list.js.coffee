class @AuditList

  @current_page = 1

  @init : () ->
    return

  @get_more_audits : ( options = {} ) ->
    @current_page = if options['page'] then options['page'] else @current_page + 1
    querystring = options

    window.location.search.replace( /([^?=&]+)(=([^&]*))?/g, ($0, $1, $2, $3) -> 
       querystring[$1] = $3 
       return
    )
    delete querystring['page'] if querystring['page']
    send_data = {}
    send_data[k] = v for k,v of querystring
    send_data['page'] = @current_page

    jQuery.ajax
      url: window.audit_search_path + '.json'
      beforeSend: (xhr) ->
        xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))
        return
      data: send_data
      success: (data) ->
        AuditList.append_audits( data.audits )
        jQuery("table#audit_list tfoot").hide() if !data.more_pages
        return
    return

  @append_audits : ( audits_to_append ) ->
    target_table_body = jQuery( "table#audit_list tbody" )
    return if audits_to_append.length == 0

    row_class = "regular" 
    for audit in audits_to_append
      rows = []
      rows.push( jQuery("<tr/>").attr("class", row_class) ) for [0..2]
      
      auditor_label_column = jQuery("<td/>").attr("class", "table_label").text("Auditor")
      auditor_value_column = jQuery("<td/>").text(audit.auditor_name.toTitleCase())
      audit_comments = if audit.comments then audit.comments else 'N/A'
      comments_column = jQuery( "<td/>").attr( "class", "audit_comments").attr("rowspan", "3").text(audit_comments)

      rows[0].append( auditor_label_column ).append( auditor_value_column ).append( comments_column )

      score_label_column = jQuery("<td/>").attr("class", "table_label").text("Score")
      score_value_column = jQuery("<td/>").text( audit.score )
      rows[1].append( score_label_column ).append( score_value_column )

      date_label_column = jQuery("<td/>").attr("class", "table_label" ).text("Date")
      date_value_column = jQuery("<td/>").text( dateFormat(audit.created_at, 'mmm dd, yyyy'))

      rows[2].append( date_label_column ).append( date_value_column )

      row_class = if row_class == "regular" then "alternate" else "regular"

      target_table_body.append( row ) for row in rows
    return
