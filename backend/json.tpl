{{header}}


Back.Dictionary = function(){
	var index = {{data}};

	return {
		translate: function(token) {
			var result = index[token];
			return (result == null) ? token : result;
		},
		getIndex : function(){
			return index;
		}
	}
}();
