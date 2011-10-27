jQuery.noConflict();
		
		function setFocusOnLoad() {}
		
		jQuery(function() {
		// Dialog			
				jQuery('#infobox').dialog({
					autoOpen: false,
					width: 850,
					height: 400,
					buttons: {
						"Close": function() { 
							jQuery(this).dialog("close"); 
						}
					}
				});
		});
				
				// Dialog Link
				function lightbox( type ) {
					jQuery('#infobox').show();
					jQuery('#infobox').dialog('open');

					return false;
				}
			
			function noenter(ev,action)  {
		   	if (window.event && window.event.keyCode == 13 || ev.which == 13) {
		   		if( action == 'saveurl')
					saveUrlAF();
				else
					setupSetControllerAF();
		       	return false;
		     	}else{
		          return true;
		     }
		   }
		   
		   function deleteURL( id, url ) {
		   	if( confirm( 'Delete url '+ url +'?' ) )
		   		delUrlAF( id );
		   		
		   	return false;
		   }