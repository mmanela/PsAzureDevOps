using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;
using Microsoft.VisualStudio.Services.Client;
using Microsoft.VisualStudio.Services.Common;

namespace VsoRestProxy
{
    public class VsoProxy
    {
        string userAgent;
        HttpClient httpClient;

        public VsoProxy(string userAgent)
        {
            this.userAgent = userAgent;
            this.httpClient = BuildHttpClient();
        }

        public HttpResponseMessage GetUrl(string url)
        {
            var response = httpClient.GetAsync(url).Result;
            return response;
        }

        public HttpResponseMessage PostUrl(string url, string payload)
        {
            var content = new StringContent(payload, Encoding.UTF8, "application/json");
            var response = httpClient.PostAsync(url, content).Result;
            return response;
        }

        public HttpClient BuildHttpClient()
        {
            VssCredentials credentials = new VssClientCredentials();
            credentials.Storage = new VssClientCredentialStorage("VssApp", "VisualStudio");
            HttpClient toReturn = new HttpClient(new VssHttpMessageHandler(credentials, new VssHttpRequestSettings()));
            toReturn.Timeout = TimeSpan.FromSeconds(30);
            toReturn.DefaultRequestHeaders.Add("User-Agent", userAgent);
            return toReturn;
        }


    }
}
