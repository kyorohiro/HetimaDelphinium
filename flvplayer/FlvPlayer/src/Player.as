package
{
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.NetStatusEvent;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.text.TextField;
	
	public class Player extends Sprite
	{
		var vi:Video = new Video();
		var totalTime:int= 0;
		var netStream:NetStream;
		var PLAY:String = "play";
		var PAUSE:String = "pause";
		var mode:String = PLAY;
		public function Player()
		{
			addChild(vi);
			var nc:NetConnection = new NetConnection();
			nc.addEventListener(NetStatusEvent.NET_STATUS, function onNetConnection(e:NetStatusEvent):void{
				switch(e.info.code)
				{
					case "NetConnection.Connect.Success":
						
						break;
				}
			});
			nc.connect(null);		
			
			var obj:Object=new Object();
			netStream =  new NetStream(nc);
			netStream.client = obj;
			
			obj.onMetaData=function(param:Object):void {
				totalTime = int(param.duration);
			};
			var paramObj:Object = loaderInfo.parameters; 
			var keyStr:String;
			var tex:String = "";
			for (keyStr in paramObj) {
				tex +=paramObj[keyStr];
				trace(keyStr);
			}
			//netStream.play("http://0.0.0.0:18085/hetima/videoplayback.flv");
			netStream.play(paramObj['flvaddr']);
			vi.attachNetStream(netStream);
			
			
			var size:int = 40;
			
			//
			// bar
			var s2:Sprite = new Sprite();
			{
				s2.graphics.beginFill(0xaaaaff);
				s2.graphics.drawRect(0, 0, vi.width, size);
				addChild(s2);
				s2.y = vi.height;
			}
			
			var x:int = size;
			//
			// play
			{
				var playButton:Sprite = new Sprite();
				playButton.buttonMode = true;
				playButton.doubleClickEnabled = true;
				playButton.mouseEnabled = true;
				
				playButton.graphics.beginFill(0xffffff);
				playButton.graphics.drawCircle(0,0,size/2);
				var playButtonLabel:TextField = new TextField();
				playButtonLabel.text = "Play";
				playButton.x = x;
				playButton.y = size/2;
				playButtonLabel.x = x;
				playButtonLabel.y = size/2;
				s2.addChild(playButton);
				s2.addChild(playButtonLabel);
				playButton.addEventListener(MouseEvent.CLICK, function clickHandler(event:MouseEvent):void 
				{ 
					if(mode == PLAY) {
						mode = PAUSE;
						netStream.pause();
					} else {
						mode = PLAY;
						netStream.resume();
					}
					playButtonLabel.text = mode;
				});
				playButton.addEventListener(MouseEvent.MOUSE_DOWN, function clickHandler(event:MouseEvent):void 
				{ 
					if(playButton.hitTestPoint(event.stageX,event.stageY)){
						playButtonLabel.textColor = 0xff0000;
					}
				});
				playButton.addEventListener(MouseEvent.MOUSE_UP, function clickHandler(event:MouseEvent):void 
				{ 
					playButtonLabel.textColor = 0x000000;
				});
			}
			
			//
			// 
			x = size*2;
			seekBar(s2,x,size);
			
			//
			//
			volumeBar(s2,x,size);
		}

		function volumeBar(s2:Sprite, x:Number, size:Number){
			var bar:SeekBar = new SeekBar(15, 20, vi.width-x*1.25);
			bar.init();
			bar.y = 20;
			bar.x = x;
			s2.addChild(bar);
			var vLabel:TextField = new TextField();
			vLabel.text = "V";
			vLabel.y = 20;
			vLabel.x = x-10;
			s2.addChild(vLabel);
			var isOn:Boolean = false;
			var moveX:int = 0;
			var buttonX:int =0;
			
			netStream.soundTransform = new SoundTransform(0.5);
			bar.setBarPosition(0.5);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, function clickHandler(event:MouseEvent):void 
			{ 
				if(!isOn &&bar.hitButton(event.stageX,event.stageY)){
					isOn = true;
					moveX = event.stageX;
					buttonX = bar.getBarPosition();
				}
			});
			stage.addEventListener(MouseEvent.MOUSE_MOVE, function clickHandler(event:MouseEvent):void 
			{ 
				if(isOn) {
					bar.move(event.stageX-moveX);
					moveX = event.stageX;
					netStream.soundTransform = new SoundTransform(bar.getBarPosition0());
				}
			});
			
			stage.addEventListener(MouseEvent.MOUSE_UP, function clickHandler(event:MouseEvent):void 
			{ 
				isOn = false;
			});
		}

		function seekBar(s2:Sprite, x:Number, size:Number){
			var bar:SeekBar = new SeekBar(15, 20, vi.width-x*1.25);
			bar.init();
			bar.x = x;
			s2.addChild(bar);
			var vLabel:TextField = new TextField();
			vLabel.text = "T";
			vLabel.x = x-10;
			s2.addChild(vLabel);	
			
			var isOn:Boolean = false;
			bar.addEventListener(Event.ENTER_FRAME, function onFrame(e:Event):void{
				if(!isOn) {
					var time = netStream.time;
					var position:Number = netStream.bytesLoaded/netStream.bytesTotal;
					bar.setBarPosition(time/totalTime);
				}
			});
			
			var moveX:int = 0;
			var buttonX:int =0;
			
			stage.addEventListener(MouseEvent.MOUSE_DOWN, function clickHandler(event:MouseEvent):void 
			{ 
				if(!isOn &&bar.hitButton(event.stageX,event.stageY)){
					isOn = true;
					moveX = event.stageX;
					buttonX = bar.getBarPosition();
					netStream.pause();
				}
			});
			stage.addEventListener(MouseEvent.MOUSE_MOVE, function clickHandler(event:MouseEvent):void 
			{ 
				if(isOn) {
					bar.move(event.stageX-moveX);
					moveX = event.stageX;
					var time:Number = bar.getBarPosition0()*totalTime;
					netStream.seek(time);
				}
			});
			
			stage.addEventListener(MouseEvent.MOUSE_UP, function clickHandler(event:MouseEvent):void 
			{ 
				isOn = false;
				if(mode == PLAY) {
					netStream.resume();
				}
			});
		}
	}
}