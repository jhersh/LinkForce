// Jonathan Hersh - jhersh@salesforce.com - 8/5/2010
public with sharing class UrlController {    
    public pageReference doRedirect() {    	
        PageReference pr = new PageReference( urlHomeController.DEFAULT_URL );
        pr.setRedirect( true );
        
        // Find our destination
        string url = Apexpages.currentpage().getparameters().get('url');
        
        if( url == null || !urlHomeController.isSetup )
            return pr;
            
        url = string.escapeSingleQuotes(url.trim());
            
        if( url.startsWith('/') )
            url = url.substring( 1, url.length() );
            
        if( url == '' )
            return pr;
        
        Short_URL__c[] urls;
        
        try {
            urls = [select id, URL__c
            from Short_URL__c
            where short_url__c = :url
            order by createddate asc limit 1];
        } catch( QueryException e ) {}
            
        if( urls == null || urls.isEmpty() )
            return pr;
            
        string redirect = urls[0].url__c;
        
        if( !redirect.tolowercase().startsWith('http://') &&
            !redirect.tolowercase().startsWith('https://') &&
            !redirect.tolowercase().startsWith('mailto:') )
            redirect = 'http://' + redirect;
            
        if( redirect.endsWith( '/' ) )
        	redirect = redirect.substring( 0, redirect.length() - 1 );
            
        pr = new PageReference( redirect );
        pr.setRedirect( true );
        
        // Save this click
        Map<string,string> headers = Apexpages.currentpage().getHeaders();
        
        Short_URL_Click__c click = new Short_URL_Click__c();
        
        click.Short_URL__c = urls[0].id;
        click.User_Agent__c = headers.get('User-Agent');
        click.IP_Address__c = headers.get('X-Salesforce-SIP');
        click.Referrer__c = headers.get('Referer');
        
        try { 
            insert click;
        } catch( Exception e ) {}
        
        return pr;
    }
    
    public static testmethod void testRedirect() {
    	PageReference notfound = new PageReference( urlHomeController.DEFAULT_URL );
    	PageReference redirect = new PageReference('http://www.salesforce.com');
    	
    	// Test a null URL
    	urlController uc = new urlController();
    	
    	PageReference p = uc.doRedirect();
    	
    	system.assertEquals( notfound.getURL(), p.getURL() );
    	
    	// Test a URL not in the system
    	Apexpages.currentpage().getparameters().put('url','lalalalalalalalalalalalalalala');
    	
    	p = uc.doRedirect();
    	
    	system.assertEquals( notfound.getURL(), p.getURL() );
    	
    	// Add a URL to the system
    	Short_URL__c url = new Short_URL__c();
    	url.url__c = redirect.getURL();
    	url.Custom_URL__c = 'lalalala';
    	
    	insert url;
    	
    	Apexpages.currentpage().getparameters().put('url','lalalala');
    	
    	p = uc.doRedirect();
    	
    	system.assertEquals( redirect.getURL(), p.getURL() );    	
    }
}