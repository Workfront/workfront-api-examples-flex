package
{
	import flash.events.Event;
	
	public class LoginEvent extends Event
	{
		public static const LOGIN:String = "LOGIN_EVENT_TYPE";
		
		private var _apiURL:String;
		private var _username:String;
		private var _password:String;
		
		public function LoginEvent(type:String, apiURL:String, username:String, password:String)
		{
			super(type, false, false);
			_apiURL = apiURL;
			_username = username;
			_password = password;
		}
		
		
		public function get apiURL():String {
			return _apiURL;
		}
		
		public function get username():String
		{
			return _username;
		}

		public function get password():String
		{
			return _password;
		}
	}
}