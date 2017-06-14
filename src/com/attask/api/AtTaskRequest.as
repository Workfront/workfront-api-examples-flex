/*
* Copyright (c) 2010 AtTask, Inc.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
* documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
* rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
* permit persons to whom the Software is furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
* Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
* WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
* COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
* OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
package com.attask.api
{
	import com.adobe.serialization.json.JSON;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLVariables;

	public class AtTaskRequest
	{
		protected var urlRequest:URLRequest;
		protected var urlLoader:URLLoader;
		
		protected var _url:String;
		protected var _requestMethod:AtTaskRequestMethod;
		protected var _callback:Function;
		
		protected var _rawResult:String;
		protected var _data:Object;
		protected var _success:Boolean;

		
		
		public function AtTaskRequest(url:String, requestMethod:AtTaskRequestMethod = null, callback:Function = null):void
		{
			_url = url;
			_requestMethod = requestMethod == null ? StreamClient.METH_GET : requestMethod;
			_callback = callback;
		}
		
		public function call(path:String, params:Object, fields:Vector.<String>, callback:Function=null):void {
			if(callback != null)
				_callback = callback;
			
			
			var requestUrl:String = _url + path;
			
			if(fields != null) {
				var fieldsParam:String = "";
				
				for each(var field:String in fields) {
					fieldsParam += escape(field) + ",";
				}
				
				if(params == null) params = new Object();
				params['fields'] = fieldsParam.substr(0, fieldsParam.lastIndexOf(","));
			}
			
			urlRequest = new URLRequest(requestUrl);
			
			urlRequest.method = _requestMethod.method;
			
			if(_requestMethod.methodOverride) {
				if(params == null) params = new Object();
				params["method"] = _requestMethod.methodOverride;
			}
						
			if(params != null)
				urlRequest.data = objectToURLVariables(params);;
			
			loadURLLoader();
		}
		
		protected function objectToURLVariables(values:Object):URLVariables {
			var urlVars:URLVariables = new URLVariables();
			if (values == null) {
				return urlVars;
			}
			
			for (var n:String in values) {
				urlVars[n] = values[n];
			}
			
			return urlVars;
		}
		
		protected function loadURLLoader():void {
			urlLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE,
				handleURLLoaderComplete,
				false, 0, false
			);
			
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR,
				handleURLLoaderIOError,
				false, 0, true
			);
			
			urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,
				handleURLLoaderSecurityError,
				false, 0, true
			);
			
			urlLoader.load(urlRequest);
		}
		
		public function close():void {
			if (urlLoader != null) {
				urlLoader.removeEventListener(
					Event.COMPLETE,
					handleURLLoaderComplete
				);
				
				urlLoader.removeEventListener(
					IOErrorEvent.IO_ERROR,
					handleURLLoaderIOError
				);
				
				urlLoader.removeEventListener(
					SecurityErrorEvent.SECURITY_ERROR,
					handleURLLoaderSecurityError
				);
				
				try {
					urlLoader.close();
				} catch (e:*) { }
				
				urlLoader = null;
			}
		}
		
		protected function handleURLLoaderComplete(event:Event):void {
			handleDataLoad(urlLoader.data);
		}
		
		protected function handleDataLoad(result:Object, dispatchCompleteEvent:Boolean = true):void {
			
			_rawResult = result as String;
			_success = true;
			
			try {
				_data = JSON.decode(_rawResult);
			} catch (e:*) {
				_data = _rawResult;
				_success = false;
			}
			
			if (dispatchCompleteEvent) {
				dispatchComplete();
			}
		}
		
		protected function dispatchComplete():void {
			_callback(this);
			close();
		}

		
		protected function handleURLLoaderIOError(event:IOErrorEvent):void {
			_success = false;
			_rawResult = (event.target as URLLoader).data;
			
			if (_rawResult != '') {
				try {
					_data = JSON.decode(_rawResult);
				} catch (e:*) {
					_data = {type:'Exception', message:_rawResult};
				}
			} else {
				_data = event;
			}
			
			dispatchComplete();
		}
		
		protected function handleURLLoaderSecurityError(event:SecurityErrorEvent):void {
			_success = false;
			_rawResult = (event.target as URLLoader).data;
			
			try {
				_data = JSON.decode((event.target as URLLoader).data);
			} catch (e:*) {
				_data = event;
			}
			
			dispatchComplete();
		}
		
		public function get success():Boolean {
			return _success;
		}
		
		public function get data():Object {
			return _data;
		}
		
		
		public function toString():String {
			return urlRequest.url +
				(urlRequest.data == null
					?''
					:'?' + unescape(urlRequest.data.toString()));
		}		
	}
}