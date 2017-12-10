using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Application as App;
using Toybox.Time.Gregorian;
using Toybox.Time;

class ActiveDotsView extends Ui.WatchFace {
	var gchFont = null;
	var activity = 15;  
	var activityCompletedPoints = 0; //Range = 0 - 15 
	var greenMode = 1; 
	var preLastSteps = Toybox.ActivityMonitor.getInfo().steps; //Number of steps in minute before the last one 
	var lastSteps = Toybox.ActivityMonitor.getInfo().steps; //Number of steps per last minute 		
	var lastActivityCheckMom = new Time.Moment(Time.now().value()); 
	var minuteActivityCheckMom = new Time.Moment(Time.now().value()); 
	var lastActivityInfo = Toybox.ActivityMonitor.getInfo().moveBarLevel;   
	var activityTimerReachedZeroMom = null;
	var STEPS_REQ_PER_MINUTE_DEFAULT = 65; 
	var STEPS_REQ_PER_TWO_MINUTES_DEFAULT = 100; 

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc) {        
        gchFont = Ui.loadResource(Rez.Fonts.goodchoiceFont);
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {
   		var clockTime = Sys.getClockTime(); 
   		var hour = clockTime.hour;
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);   
   		var myStats = Sys.getSystemStats();
        var battery = myStats.battery;        
        var activityInfo = Toybox.ActivityMonitor.getInfo();     
        var stepPercent = activityInfo.steps.toFloat()/activityInfo.stepGoal.toFloat() * 100; 
        var distance = 0; 
		if(activityInfo.distance > 0) {
			//Set distance in kilometers 
			distance = activityInfo.distance / 100000.0;
		}
        
        //Update activityCompletedPoints
        updateActivityCompletedPoints(stepPercent);
               
        //Prepare strings        
        var stepPercentStr = Lang.format("$1$%",[stepPercent.format("%d")]); 		
		var stepsStr = activityInfo.steps;	
		var batStr = Lang.format( "$1$%", [ battery.format( "%2d" ) ] );		
		var distanceStr = distance.format("%.1f");         
        var dateStr = Lang.format("$1$.$2$.$3$", [today.day.format("%02d"), today.month.format("%02d"), today.year]);
		
		//Repaint 
		dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK); 
		dc.clear();   
        
        //Draw main components 
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
        dc.drawText(dc.getWidth()/2, 5, Gfx.FONT_MEDIUM, dateStr, Gfx.TEXT_JUSTIFY_CENTER);
        
        //Show percents
        if(Application.getApp().getProperty("ShowPercents") == true) {
        	dc.drawText(dc.getWidth()/4+10, dc.getHeight()-40, Gfx.FONT_SMALL, batStr, Gfx.TEXT_JUSTIFY_CENTER);
        	dc.drawText(dc.getWidth()/4*3-10, dc.getHeight()-40, Gfx.FONT_SMALL, stepPercentStr, Gfx.TEXT_JUSTIFY_CENTER);
        }        
        //Show details
        if(Application.getApp().getProperty("ShowDetails") == true) {
        	dc.drawText(dc.getWidth()/4+10, dc.getHeight()-20, Gfx.FONT_SMALL, distanceStr+"km", Gfx.TEXT_JUSTIFY_CENTER);
        	dc.drawText(dc.getWidth()/4*3-10, dc.getHeight()-20, Gfx.FONT_SMALL,stepsStr, Gfx.TEXT_JUSTIFY_CENTER);
        }               
        dc.drawText(dc.getWidth()/2-5, dc.getHeight()/2-40, gchFont, Lang.format("$1$", [clockTime.hour.format("%02d")])  , Gfx.TEXT_JUSTIFY_RIGHT);
           
        updateActivity(dc);   
        updateMoveAlert(dc);
        
        lastActivityInfo = Toybox.ActivityMonitor.getInfo().moveBarLevel; 
    }   

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
    }
    
    // Sets activityCompletedPoints (0-15) based on stepPercent
    function updateActivityCompletedPoints(stepPercent){
    	activityCompletedPoints = stepPercent * 0.15; 
        //Must be within range 0 - 15 
        if (activityCompletedPoints > 15) {
        	activityCompletedPoints = 15; 
        }
        if (activityCompletedPoints < 0) {
        	activityCompletedPoints = 0; 
        }
    }    
    
    function rechargeActivityPoints(activityInfo){
    	activity = 15;    		
    	greenMode = 1;
    	preLastSteps = activityInfo.steps;	
    	lastSteps = activityInfo.steps;	
    	lastActivityCheckMom = new Time.Moment(Time.now().value()); 
    	activityTimerReachedZeroMom = null; 
    }
    
    //Keeps track of active dots 
    function updateActivity(dc) {
    	var activityInfo = Toybox.ActivityMonitor.getInfo();
    	
    	if (activityInfo.steps < lastSteps) {
    		//A new day started 
    		preLastSteps = activityInfo.steps;
    		lastSteps = activityInfo.steps;
    		lastActivityCheckMom = new Time.Moment(Time.now().value());  
    		activityCompletedPoints = 0; 
    	}
    	
    	if(lastActivityInfo > 0 and activityInfo.moveBarLevel == 0) {
    		//Activity move bar was just reset - recharge activity points 
    		rechargeActivityPoints(activityInfo); 
    	}
    	
    	//Get required steps + check validity 
    	var stepsPerMinute = Application.getApp().getProperty("ReqStepsPerMinute"); 
    	if(stepsPerMinute < 30 or stepsPerMinute > 150) {
    		stepsPerMinute = STEPS_REQ_PER_MINUTE_DEFAULT; 
    	}
    	var stepsPerTwoMinutes = Application.getApp().getProperty("ReqStepsPerTwoMinutes"); 
    	if(stepsPerMinute < 50 or stepsPerMinute > 200) {
    		stepsPerTwoMinutes = STEPS_REQ_PER_TWO_MINUTES_DEFAULT; 
    	}
    	if ( ((activityInfo.steps - lastSteps) >= stepsPerMinute) or ((activityInfo.steps - preLastSteps) >= stepsPerTwoMinutes) ) { 
    		//Enough steps, recharge activity points    
    		rechargeActivityPoints(activityInfo); 
    	} else {     		
    		var todayMom = new Time.Moment(Time.now().value());   
    		var diffMin = todayMom.subtract(minuteActivityCheckMom);
    		if(diffMin.value() >= 60) {    					
    			//Reset steps for the last minute / two minutes 
    			preLastSteps = lastSteps; 
    			lastSteps = activityInfo.steps;	//Maybe some steps added, maybe not 
    			minuteActivityCheckMom = new Time.Moment(Time.now().value());     			
    		}    		
	    	var diff = todayMom.subtract(lastActivityCheckMom);
	    	if (diff.value() >= 60*4 and activity > 0) { 
	    		//Not enough steps per last 4 minutes = loose a point
	    		activity--;
	    		greenMode = 0; 
	    		lastActivityCheckMom = new Time.Moment(Time.now().value());  
	    		if(activity == 0) {
	    			activityTimerReachedZeroMom = new Time.Moment(Time.now().value()); 
	    		}
	    	}
	    }	
    }
    
    //Draws dots and minutes 
    function updateMoveAlert(dc) {
    	//215x180 = 215-60 = 155    	
        var activityInfo = Toybox.ActivityMonitor.getInfo();
        var clockTime = Sys.getClockTime();   
        var diff = 0; 
        if (activityTimerReachedZeroMom != null) {
        	var todayMom = new Time.Moment(Time.now().value());   
    		diff = todayMom.subtract(activityTimerReachedZeroMom); 
        }        
        if (diff != 0 and diff.value() >= 5*60 and activityInfo.moveBarLevel == 0){ //After 5 minutes should be fine (previously 3600) 
        	//Watch is in sleep mode - no need to draw points - return
        	//Note: activityInfo.isSleepMode is not working on a real device        
        	dc.drawText(dc.getWidth()/2+5, dc.getHeight()/2-40, gchFont, Lang.format("$1$", [clockTime.min.format("%02d")]), Gfx.TEXT_JUSTIFY_LEFT); 
        	return;    	
        }else{
        	//Not in sleep mode  
        	var j = 0; //For activityCompletedPoints 
        	if (activityInfo.moveBarLevel == 0) {
        		//Still active (no inactivity alert)   
        		if(greenMode == 1) {        			      			
        			dc.setColor(Application.getApp().getProperty("ActiveColor"), Gfx.COLOR_TRANSPARENT);
        			dc.drawText(dc.getWidth()/2+5, dc.getHeight()/2-40, gchFont, Lang.format("$1$", [clockTime.min.format("%02d")]), Gfx.TEXT_JUSTIFY_LEFT);
        			for(var i = 1; i <= 15; i++) { 
        				if (i <= activityCompletedPoints) {	
        					dc.setColor(Application.getApp().getProperty("ActiveColor"), Gfx.COLOR_TRANSPARENT);        			
		        			dc.fillCircle(dc.getWidth()/2, 208-(i*10+24), 3);		        			
		        		} else{
		        			dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);	
		        			dc.fillCircle(dc.getWidth()/2, 208-(i*10+24), 3);
		        		}	
        			}
        		}else{
        			//Normal mode - siting for some time, but still no inactivity alert  
        			//var minuteColor = Gfx.COLOR_LT_GRAY;
        			var minuteColor = Application.getApp().getProperty("SittingColor4");
		        	for(var i = 15; i > 0; i--) {
		        		if (i <= (15-activity)) {
		        			dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);		        			
		        		}else{
		        			if (activity >= 10) { 		        				
		        				minuteColor = Application.getApp().getProperty("SittingColor");
		        			}else if (activity >= 7) { 		        				
		        				minuteColor = Application.getApp().getProperty("SittingColor2");
		        			}else if (activity >= 4) { 		        				
		        				minuteColor = Application.getApp().getProperty("SittingColor3");
		        			}	        			
		        			else{		        				
		        				minuteColor = Application.getApp().getProperty("SittingColor4");
		        			}    		        			
		        			dc.setColor(minuteColor, Gfx.COLOR_TRANSPARENT);	    	
		        		}		        		
		        		dc.fillCircle(dc.getWidth()/2, i*10+24, 3); 		        			        		
		        	} 		        	
		        	dc.setColor(minuteColor, Gfx.COLOR_TRANSPARENT);	        	
		        	dc.drawText(dc.getWidth()/2+5, dc.getHeight()/2-40, gchFont, Lang.format("$1$", [clockTime.min.format("%02d")]), Gfx.TEXT_JUSTIFY_LEFT);
        		}        		
        	}else{
        		//Inactivity alert by Garmin    
        		activity = 0; 
        		activityTimerReachedZeroMom = new Time.Moment(Time.now().value()); 
        		for(var i = 1; i <= 15; i++) {         			 
        			if (i/3.0 <= activityInfo.moveBarLevel) { //5 levels = each level has 3 dots        				
        				dc.setColor(Application.getApp().getProperty("IdleColor"), Gfx.COLOR_TRANSPARENT);
        				dc.fillCircle(dc.getWidth()/2, 208-(i*10+24), 3);
        			}else{
        				dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
        				dc.fillCircle(dc.getWidth()/2, 208-(i*10+24), 3);        				
        			}
        		}        		
        		dc.setColor(Application.getApp().getProperty("IdleColor"), Gfx.COLOR_TRANSPARENT);
	        	dc.drawText(dc.getWidth()/2+5, dc.getHeight()/2-40, gchFont, Lang.format("$1$", [clockTime.min.format("%02d")]), Gfx.TEXT_JUSTIFY_LEFT);
        	}        
        	
        }     
        
	}

}
