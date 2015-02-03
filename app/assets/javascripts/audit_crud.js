angular.module('audit',["ngSanitize", "ngS3upload"])
	.run(['$rootScope', '$window', function( $rootScope, $window){
		$rootScope.show_store_search = $window.show_store_search;
		$rootScope.audit_store_id = $window.audit_store_id;
	}])
	.service( "StoreSearch", ['$http', '$q', '$window', function($http, $q, $window){
		var storeSearchUrl = $window.api_v1_stores_search_path;
		var save_location = null;
		return {
			setlocation: function(position){
				save_position = position;
			},

			findStores: function( query, dist, page, position){
				var deferred_geo = $q.defer();
				var query_distance = (parseFloat(dist) > 0 ? dist : null );
				
				var http_params = { q: query, distance: query_distance, page: page};

				if(query_distance != null && save_location == null && position == null){
					if ($window.navigator.geolocation) {
						$window.navigator.geolocation.getCurrentPosition(function(position){
							save_location = position;
							deferred_geo.resolve(position);
						},
						function(errObj){
							save_location = null;
							deferred_geo.reject(errObj);
						});
					}
				}
				else
					deferred_geo.resolve(position || save_location);


				return deferred_geo.promise.then(function(position) {
						if(position != null){
							http_params.lat = position.coords.latitude;
							http_params.lon = position.coords.longitude;
						}
						return $http({
								method: 'GET',
								url: storeSearchUrl,
								params: http_params
						});
					} 
				); 
				
			}

		}
	}])
	.service( "GMaps", ['$http', '$q', function($http,$q){
		return {

			getPosition: function(address){
				var deferred = $q.defer();

				$http.get('https://maps.googleapis.com/maps/api/geocode/json',{
					params: {
						sensor: false,
						address: address
					}
				}).then(function(result){
					var location = result.data.results[0].geometry.location;
					deferred.resolve({coords: {latitude: location.lat, longitude: location.lng}});
				},function(){});

				return deferred.promise;
			}
		}
	}])
	.factory( "StoreExchange", ['$rootScope',function($rootScope){

		var store_id = 0;
		var store_full_name = null;
		var store_address = null;
		var store_store_number = null;

		return {
			setSelectedStore: function(storeObject){

				store_id = parseInt(storeObject.id);
				store_full_name = storeObject.full_name;
				store_address = storeObject.address;
				store_store_number = storeObject.store_number;

				$rootScope.audit_store_id = store_id;

				$rootScope.$broadcast("storeChanged");
			},

			getSelectedStore: function(){
				return {
					id: store_id,
					full_name: store_full_name,
					address: store_address,
					store_number: store_store_number
				}
			}
		};
	}])
	.factory( "totalScore", ['$rootScope', function($rootScope){
		var metrics = [];		
		var finalScore = {
			base: 0,
			loss: 0,
			bonus: 0		
		}

		var retVal = {};

		retVal.addMetric = function(){
			metrics.push({
				base: 0,
				loss: 0,
				bonus: 0,
			});
		}

		retVal.addScore = function( index, baseScore, lossScore, bonusScore){
			metrics[index] = {
				base: baseScore,
				loss: lossScore,
				bonus: bonusScore
			};

			$rootScope.$broadcast("totalScoreChanged");
		}

		retVal.calculateScore = function(){
			finalScore = {
				base: 0,
				loss: 0,
				bonus: 0
			};

			for(i = 0; i < metrics.length; i++){
				finalScore.base += metrics[i].base;
				finalScore.loss += metrics[i].loss;
				finalScore.bonus += metrics[i].bonus;
			}

			return finalScore;
		}

		return retVal;
	}])
	.controller('StoreController', ['$scope', '$rootScope', "StoreExchange", function( $scope, $rootScope, StoreExchange){
		$scope.full_name = '';
		$scope.address = '';
		$scope.store_number = '';

		$scope.init = function( store_id, storeFullName, storeAddress){
			if(store_id > 0){
				StoreExchange.setSelectedStore( {id: store_id, full_name: storeFullName, address: storeAddress, store_number: ($scope.store_number || null)});
			}
		}

		$scope.changeStore = function(){
			$rootScope.show_store_search = true;
		}

		$scope.$on('storeChanged', function(){
			var storeObject = StoreExchange.getSelectedStore();
			$scope.store_id = storeObject.id;
			$scope.full_name = storeObject.full_name;
			$scope.address = storeObject.address;
			$scope.store_number = storeObject.store_number;
		})
	}])
	.controller('StoreSearchController', ['$scope', 'StoreExchange' ,'StoreSearch', 'GMaps', '$window', '$rootScope', function($scope, StoreExchange, StoreSearch, GMaps, $window, $rootScope){
		$scope.stores = null;
		$scope.more_pages = false;
		$scope.current_page = 1;
		$scope.query_string = null;
		$scope.loading = false;
		$scope.loading_message = null;
		$scope.allow_next_page = false;

		var saved_result_pages = [];
		var total_stores_returned = 0;

		$scope.init = function(initial_miles){
			$scope.dist = initial_miles;
		}

		var preloadStores = function(){
			$scope.allow_next_page = false;
			StoreSearch.findStores( 
							$scope.query_string, 
							$scope.dist, 
							$scope.current_page + 1, 
							($scope.locationPoint == 1 ? GMaps.getPosition($scope.ref_address).then(function(data) {return data;}, function(){return null;}) : null)
			).then(function(payload){
				saved_result_pages.push(payload.data.results);
				$scope.allow_next_page = true;
			}, function(){
				// Need to handle error when page cannot
				// be preloaded
			});
		}

		$scope.cancel = function(){
			$rootScope.show_store_search = false;
		}

		$scope.getStores = function(page){
			$scope.stores = [];	
			$scope.allow_next_page = false;
			if(page == null || page == 1)	$scope.more_pages = false;

			$scope.loading = true;
			$scope.loading_message = "Searching ... ";

			var store_search_promise = StoreSearch.findStores( 
				$scope.query_string, 
				$scope.dist, 
				page, 
				($scope.locationPoint == 1 ? GMaps.getPosition($scope.ref_address)
					.then(
						function(data) {						
							return data;
						}, 
						function(){
							return null;
						}) 
					: null)
			);
			store_search_promise
				.then(
					function(payload){

						$scope.loading = false;
						$scope.loading_message = null;

						$scope.current_page = payload.data.page;
						
						if($scope.current_page == 1) {
							saved_result_pages = [];
							total_stores_returned = payload.data.total;
						}
						
						$scope.stores = payload.data.results;
						$scope.more_pages = payload.data.more_pages;
						saved_result_pages.push(payload.data.results);

						if(payload.data.more_pages){
							// Preload another page to avoid page-flicker
							preloadStores();
						}
					},
					function(errorPayLoad){	

						$scope.loading = false;
						$scope.loading_message = null;

						$scope.more_pages = false;
						console.log( errorPayLoad);
					}
				);
		}

		$scope.previousPage = function(){
			$scope.current_page--;
			$scope.stores = saved_result_pages[$scope.current_page - 1];

			// As this function is called from clicking the Back
			// button on a section, we are assured that there are more
			// pages. 
			$scope.more_pages = true;
		}

		$scope.nextPage = function(){
			// Because of various flags put into place
			// this function cannot be reached unless there are more pages
			// So it is safe to increment the page counter at this time.
			$scope.current_page++;
			var total_pages = $window.Math.round(total_stores_returned/5);
			$scope.stores = saved_result_pages[$scope.current_page - 1];
			$scope.more_pages  = ($scope.current_page < total_pages);
			if($scope.more_pages && saved_result_pages.length == $scope.current_page)
				preloadStores();
			
		}

		$scope.selectStore = function(obj){
			StoreExchange.setSelectedStore( obj );
			$rootScope.show_store_search = false;
		}
	}])
	.controller('AuditController',['$scope', 'totalScore',function($scope, totalScore){
		$scope.baseScore = 0;
		$scope.lossScore = 0;
		$scope.bonusScore = 0;
		$scope.Math = window.Math;

		$scope.init = function( initial_values){
			if(initial_values != null){
				$scope.baseScore = initial_values.base;
				$scope.lossScore = initial_values.loss;
				$scope.bonusScore = initial_values.bonus;
			}
		}


		$scope.$on('totalScoreChanged', function(){
			var auditScore = totalScore.calculateScore();
			$scope.baseScore = auditScore.base;
			$scope.lossScore = auditScore.loss;
			$scope.bonusScore = auditScore.bonus;
		})
	}])
	.controller('AuditImageController', ['$scope', function($scope){
		$scope.files = {};

	}])
	.controller('AuditMetricController', ['$scope', 'totalScore', 'StoreExchange', function($scope, totalScore, StoreExchange) {
		$scope.comparisonType = null;
		$scope.metricScoreType = null;
		$scope.computedBaseScore = 0;
		$scope.computedLossScore = 0;
		$scope.computedBonusScore = 0;
		$scope.entry_values = [];
		$scope.entry_value_weights = [];
		$scope.entry_value_scores = [];
		$scope.entry_value_scoreTypes = [];
		$scope.metricIndex = 0;
		$scope.needsResolution = false;
		$scope.resolved = false;
		
		
		$scope.init = function( comparisonType, scoreType, needsResolution, index, initial_values ){
			$scope.comparisonType = comparisonType;
			$scope.metricScoreType = scoreType;
			$scope.metricIndex = index;
			$scope.needsResolution = needsResolution;
			totalScore.addMetric();
			if(initial_values != null){
				$scope.computedBaseScore = initial_values.base;
				$scope.computedLossScore = initial_values.loss;
				$scope.computedBonusScore = initial_values.bonus;
				$scope.resolved = initial_values.resolved;
				totalScore.addScore( $scope.metricIndex, $scope.computedBaseScore, $scope.computedLossScore, $scope.computedBonusScore);

			}
		}
		
		$scope.calculateScore = function(){
			var baseScore = 0;
			var bonusScore = 0;
			var lossScore = 0;
			var score = 0;
			switch($scope.comparisonType)
			{
				case 'radio':
					score = $scope.score;

					break;
				case 'text_compare':
					if($scope.entry_values.length < 2) return 0;
					var maxWeightIndex = $scope.entry_value_weights.indexOf(Math.max.apply(Math, $scope.entry_value_weights));
					var maxValueIndex = $scope.entry_values.indexOf(Math.max.apply(Math, $scope.entry_values));
					var compareValue = parseInt($scope.entry_values[maxWeightIndex]);
					var targetValue = parseInt($scope.entry_values[maxValueIndex]);
					

					// The indexes between the three arrays are synchronised at initialisation
					// So if the index of the max value in the entry_values array matches the
					// index of the max weight then entry_value_weights array then the correct
					// highest weighted entry has the highest value as well. The only edge case
					// scenario for this logic is that if there is another element in the array that 
					// has a value equal to highest weighted value. Hence the compareValue == targetValue
					// comparison in case the maxValueindex and maxWeightIndex do not match up. 
					if(maxValueIndex == maxWeightIndex || compareValue == targetValue)
						score = $scope.entry_value_scores[maxWeightIndex];
					
					break;
				case 'custom_shelves':
					// If full door is selected then no need to do any computation
					if( $scope.entry_values.length == 7 && $scope.entry_values[6] == 1 )
					{
						baseScore = 0;
						bonusScore = 1;
						lossScore = 0;
						// Clear all other shelves if full door is selected
						for( i = 0; i < 6 ; i++) $scope.entry_values[i] = null;
						break;
					}
					
					// If full door is not selected then compute necessary values
					var iterations = ($scope.entry_values.length > 6 ? 6 : $scope.entry_values.length);
					for( i = 0; i < iterations; i++){
						// If the checkbox is not selected then no need to do any computation for this
						// iteration
						if($scope.entry_values[i] != 1) continue;
						
						// Depending on the score type assign the computed value 
						// to the correct variable.
						var score = $scope.entry_value_scores[i] * $scope.entry_value_weights[i];
						switch($scope.entry_value_scoreTypes[i]){
							case 'base':
								baseScore += score;
								break;
							case 'loss':
								lossScore += score;
								break;		
							case 'bonus':
								bonusScore += score;
								break;		
						}
					}
					break;
				case 'computed':
					if( typeof $scope.quantifier === 'undefined') break;
					var score = $scope.entry_value * parseFloat($scope.quantifier);

					break;
				}
				
				// This computation section is already happening for 
				// custom_shelves hence no need to do it here. 
				if($scope.comparisonType != "custom_shelves")
				{
					switch($scope.metricScoreType)
					{
						case 'base':
							baseScore = score;
							break;
						case 'bonus':
							bonusScore = score;
							break;
						case 'loss':
							lossScore = score;
							break;	
					}
				}

				$scope.computedBaseScore = Math.round(baseScore);
				$scope.computedLossScore = Math.round(lossScore);
				$scope.computedBonusScore = Math.round(bonusScore);
				
				totalScore.addScore( $scope.metricIndex, $scope.computedBaseScore, $scope.computedLossScore, $scope.computedBonusScore);
				
				return;
			}
			
		}]);