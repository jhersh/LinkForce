// Jonathan Hersh - jhersh@salesforce.com - 8/6/2010
public with sharing class urlHomeController {
	public Short_URL__c newURL			{ get; set; }
	public Short_URL__c[] urls			{ get; set; }
	public Short_URL_Click__c[] clicks	{ get; set; }
	public string sortBy				{ get; set; }
	public string sortOrder				{ get; set; }
	public boolean showEditBox			{ get; set; }
	
	public string urlID					{ get; set; }
	public string searchStr				{ get; set; }
	
	public integer ROWS_PER_PAGE		{ get { return 20; } }
	
	public static boolean isSetup		{ get { return LinkForce_Settings__c.getInstance() != null &&
												LinkForce_Settings__c.getInstance().Base_URL__c.length() > 0 && 
												LinkForce_Settings__c.getInstance().Default_URL__c.length() > 0; } }
	
	public static string URL_BASE	{ get { 
		if( !isSetup )
			return '';
			
		string url = LinkForce_Settings__c.getInstance().Base_URL__c;
		
		if( !url.startsWith('http://') &&
            !url.startsWith('https://') &&
            !url.startsWith('mailto:') )
            url = 'http://' + url;
        
        // Pagereferences seem to have issues with a trailing slash    
        if( url.endsWith('/') )
        	url = url.substring( 0, url.length() - 1 );
        	
        return url;
	} }
	
	public static string DEFAULT_URL	{ get { 
		if( !isSetup )
			return 'http://www.salesforce.com';
			
		string url = LinkForce_Settings__c.getInstance().Default_URL__c;
		
		if( !url.startsWith('http://') &&
            !url.startsWith('https://') )
            url = 'http://' + url;
            
        if( url.endsWith('/') )
        	url = url.substring( 0, url.length() - 1 );
        	
        return url;
	} }
	
	// Set controller variables
	private ApexPages.StandardSetController setController;
	public Integer pageNum 	{ get; set; }
	
	public Boolean hasNextPage {get{
		return this.setController.getHasNext();
		}
	private set;}
	
	public Boolean hasPreviousPage{get {
		return this.setController.getHasPrevious();
	}
	private set;}

	public String totalPages { get {
        if(this.setController != null){
        	Double doublePageNum = (Double)this.setController.getResultSize()/this.setController.getPageSize();
	        Decimal numOfPages = Decimal.valueOf(doublePageNum).round(RoundingMode.CEILING);
	        return numOfPages == 0 ? '1' : String.valueOf(numOfPages);
        }else{
        	return '1';
        }
    } private set; }
	
	public urlHomeController() {
		newURL = new Short_URL__c();
		urls = new Short_URL__c[] {};
		clicks = new Short_URL_Click__c[] {};
		sortby = 'createddate';
		sortOrder = 'descending';
		pageNum = 1;
		showEditBox = false;
				
		setupSetController();
	}
	
	public void resetURL() {
		newURL = new Short_URL__c();
		showEditBox = false;
	}
	
	public void setupSetController() {			
		string query = 'select id, name, short_url__c, clicks__c, url__c, '+
			'createdbyid, createddate '+
			'from Short_URL__c ';
			
		// Are we here for a search? SOSL doesn't support wildcards at the start of a search term
		if( searchStr != null && searchStr != '' ) 
			query += 'where short_url__c LIKE \'%'+ searchStr + '%\' or '+
				'url__c LIKE \'%'+ searchStr +'%\' or '+
				'createdby.name LIKE \'%'+ searchStr +'%\' ';
					
		query += 'order by ';
			
		string qsort;
			
		if( sortOrder == 'descending' )
			qsort = 'desc';
		else
			qsort = 'asc';
			
		if( sortby == 'createdby' )
			query += 'createdby.lastname '+ qsort +', createdby.firstname '+ qsort;
		else if( sortby == 'clicks' )
			query += 'clicks__c '+ qsort;
		else if( sortby == 'shorturl' )
			query += 'short_url__c '+ qsort;
		else if( sortby == 'url' )
			query += 'url__c '+ qsort;
		else
			query += 'createddate '+ qsort;
			
		this.pageNum = 1;			
		this.setController = urlHomeController.createStandardSetController(query, ROWS_PER_PAGE);
	    this.setController.setPageNumber(1);
	    
	    urls = this.setController.getRecords();
	}
	
	private static String convertInt ( integer num ) {  
        String tempVal = num == 0 ? '0' : ''; 
        integer mod = 0;  
        integer base = 36;
        
        String baseDigits = '0123456789abcdefghijklmnopqrstuvwxyz';
  
        while( num != 0 ) {  
            mod = Math.mod( num, base );  
            tempVal = baseDigits.substring( mod, mod + 1 ) + tempVal;  
            num /= base;  
        }  
  
        return tempVal;  
    } 
	
	public void saveURL() {
		if( newURL.url__c == null ) {
			newURL.url__c.addError('Please enter a URL to shorten.');
			return;
		}

		// Ensure they haven't tried to stick anything extra in the custom URL field
		if( newURL.custom_url__c != null ) {
			newURL.custom_url__c = newURL.custom_url__c.tolowercase().trim();
			
			// Make sure they didn't put a URL in there
			newURL.custom_url__c = newURL.custom_url__c.replace( URL_BASE.tolowercase(), '' ).replace( 'http://', '' ).replace( '/', '' );
			
			// Character-level filtering.
			if( !Pattern.matches( '^[a-z0-9]+$', newURL.custom_url__c ) ) {
				newURL.custom_url__c.addError('Invalid custom URL. Letters and numbers only.');
				return;
			}		
			
			// Be doubly sure that this short URL hasn't been taken
			Short_URL__c[] urls = [select id
				from Short_URL__c
				where id <> :newURL.id and 
				( hashed_url__c = :newURL.custom_url__c OR custom_url__c = :newURL.custom_url__c ) ];
				
			if( !urls.isEmpty() ) {
				newURL.custom_url__c.addError('This short URL is already taken. Please choose another.');
				return;
			}			
		}
		
		try {
			upsert newURL;
		} catch( Exception e ) {
			Apexpages.addMessages(e);
			return;
		}
		
		// get the new url's name (an auto-number) and convert to text
		newURL = [select id, name, custom_url__c, hashed_url__c, short_url__c
				from Short_URL__c
				where id = :newURL.id limit 1];
				
		newURL.hashed_url__c = convertInt( integer.valueof( newURL.name ) );
			
		try { 
			update newURL;	
		} catch( Exception e ) {
			Apexpages.addMessages(e);
			return;
		}
		
		ApexPages.addMessage( new ApexPages.Message( Apexpages.Severity.INFO, 
			'Successfully shortened to '+ URL_BASE + '/' +
			( newurl.custom_url__c == null ? newURL.hashed_url__c : newURL.custom_URL__c ) ) );
		
		showEditBox = false;
		newURL = new Short_URL__c();
		setupSetController();
	}
	
	public void deleteURL() {
		if( urlID == null || urlID == '' )
			return;
			
		try {
			Short_URL__c toDel = [select id
				from Short_URL__c
				where id = :urlID limit 1];
				
			delete toDel;
		} catch( Exception e ) {
			ApexPages.addMessages( e );
		}
		
		showEditBox = false;
		setupSetController();
	}
	
	// Load in a URL for editing
	public void loadURL() {
		newURL = new Short_URL__c();
		
		if( urlID == null || urlID == '' )
			return;
			
		Short_URL__c[] urls = [select id, url__c, custom_url__c
			from Short_URL__c
			where id = :urlID limit 1];
			
		if( urls.isEmpty() )
			return;
		
		showEditBox = true;
		newURL = urls[0];
	}
	
	public void renderEditBox() {
		showEditBox = true;
	}
	
	// Loads in the clicks for a URL
	public void loadURLClicks() {
		clicks = new Short_URL_Click__c[] {};
		
		if( urlID == null || urlID == '' )
			return;
			
		clicks = [select id, createddate, user_agent__c, ip_address__c, referrer__c, os__c, browser__c
			from Short_URL_Click__c
			where short_url__c = :urlID
			order by createddate desc limit 500];
	}
	
	public SelectOption[] getSortOptions() {
		SelectOption[] so = new SelectOption[] {};
		
		for( string s : new string[] { 'Short URL', 'URL', 'Clicks', 'Created Date', 'Created By' } )
			so.add( new SelectOption( s.tolowercase().replace(' ', ''), s ) );
			
		return so;
	}
	
	public SelectOption[] getSortOrders() {
		SelectOption[] so = new SelectOption[] {};
		
		for( string s : new string[] { 'Ascending', 'Descending' } )
			so.add( new SelectOption( s.tolowercase().replace(' ', ''), s ) );
			
		return so;
	}
	
	public void nextLinks() {
		pageNum++;
		
		setController.next();
		urls = this.setController.getRecords();
	}

	public void prevLinks() {
		pageNum--;

		setController.previous();
		urls = this.setController.getRecords();
	}
	
	public static ApexPages.StandardSetController createStandardSetController(String pQueryString, Integer pPageSize){
		ApexPages.StandardSetController returnSet;
		if(pQueryString != null && pPageSize != null){
			returnSet = new ApexPages.StandardSetController(Database.getQueryLocator(pQueryString));
			// we need this due to a bug in Visualforce : see 
            // http://community.salesforce.com/sforce/board/message?board.id=Visualforce&message.id=17035 
            if (returnSet.getResultSize() > 0) {
                returnSet.setPageSize(pPageSize);
            }
		}
		return returnSet;
	}
	
	public static testmethod void runTest() {
		// Add a URL
		Short_URL__c url = new Short_URL__c();
		url.url__c = 'www.salesforce.com';
		insert url;
		
		urlHomeController uhc = new urlHomeController();
		
		// Static form functions
		uhc.nextLinks();
		uhc.prevLinks();
		uhc.getSortOptions();
		uhc.getSortOrders();
		uhc.resetURL();
		
		string s = urlHomeController.URL_BASE;
		s = urlHomeController.DEFAULT_URL;
		
		system.assertEquals( true, uhc.totalPages != '0' );
		
		// Save a URL without specifying the url?
		uhc.saveURL();
		
		Short_URL__c[] urls = [select id from Short_URL__c where url__c = 'http://her.sh' limit 1];
		
		system.assertEquals( 0, urls.size() );
		
		// Now specify the URL
		uhc.newURL.url__c = 'http://her.sh';
		uhc.saveURL();
		
		urls = [select id from Short_URL__c where url__c = 'http://her.sh' limit 1];
		
		system.assertEquals( 1, urls.size() );
		
		// Delete that URL
		uhc.urlID = urls[0].id;
		
		uhc.loadURL();
		uhc.loadURLClicks();
		
		uhc.deleteURL();
		
		urls = [select id from Short_URL__c where url__c = 'http://her.sh' limit 1];
		
		system.assertEquals( 0, urls.size() );
	}
}