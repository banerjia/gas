class @Store 
	api_url= null
	
	constructor: ->
		if arguments.length > 0
			api_url=  arguments[0].url
		return
	
	getRegionsByCompany: (company_id, targetObject) ->
		targetObjectId = $(targetObject)
		callback = @refreshRegionsDropDown
		$.ajax {
			url: api_url 
			data: {
				company_id: company_id
			}
			success: (data) ->
				if data != null
					callback data, targetObjectId
				return		
		}
		return
		
	refreshRegionsDropDown: (regions, regionsDropDown) ->
		$(regionsDropDown).empty()
		
		$(regionsDropDown).prop "disabled", (regions.length == 0)
				
		$(regionsDropDown).append "<option value=''>-- Select --</option>"
		for region in regions
			$(regionsDropDown).append "<option value='" + region.id + "'>" + region.name + "</option>"
		return
	
	checkForEmpty: (sender) ->
		console.log $(sender).val().trim().length
		return if !$(sender).val()? or $(sender).val().trim().length > 0 
		$("input.address-entries").val ""
		return
		