class @GoogleMapsAutoComplete
	componentForm = {
		route: { element: 'store_street_address', component: 'long_name' }
		street_number: { element: 'store_street_address', component: 'long_name' }
		locality: { element: 'store_city', component: 'long_name' }
		country: { element: 'store_country', component: 'short_name' }
		administrative_area_level_1: { element: 'store_state_code', component: 'short_name' }
		administrative_area_level_2: { element: 'store_county', component: 'long_name' }
		postal_code: { element: 'store_zip', component:'short_name'}
	}
	
	place = autocomplete = null
	addressSearchElementId = "addressSearch"
	
	constructor: ->
		componentForm = arguments[1] if arguments.length > 1
		addressSearchElementId = arguments[0] if arguments.length > 0
		initialize()
		return

	initialize = () ->				
		autocomplete = new google.maps.places.Autocomplete document.getElementById(addressSearchElementId), {types: ['establishment'], componentRestrictions: {country: 'us'}}	
		google.maps.event.addDomListener document.getElementById(addressSearchElementId), 'keydown', (e) ->  
			e.preventDefault() if (e.keyCode == 13)
			return
			
		google.maps.event.addListener autocomplete, 'place_changed', () ->
			fillInAddress()
			return
		return
	
	fillInAddress = () ->
		place = autocomplete.getPlace()
		for component in Object.keys(componentForm)
			do (component) ->
				elementID = componentForm[component].element
				$("#" + elementID).val('') if $("#" + elementID).is("input")
				return
		
		for addr_component in place.address_components
			do (addr_component) ->
				addressType = addr_component.types[0]
				if componentForm[addressType]
					valueOfAddressComponent = addr_component[componentForm[addressType].component]
					targetObject = $("#" + componentForm[addressType].element)
					if targetObject.is("input")
						valueOfAddressComponent = " " + valueOfAddressComponent if targetObject.val().length > 0
						targetObject_NewValue = targetObject.val() + valueOfAddressComponent
					else
						targetObject_NewValue = valueOfAddressComponent
					targetObject.val( targetObject_NewValue )
				return
		return
