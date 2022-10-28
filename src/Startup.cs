using Prometheus;
using Microsoft.AspNetCore.Http;
using System.Diagnostics;

using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.HttpsPolicy;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.OpenApi.Models;

namespace DemoApi
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            services.AddControllers();
            services.AddSwaggerGen(c =>
            {
                c.SwaggerDoc("v1", new OpenApiInfo { Title = "WeatherForecastApi", Version = "v1" });
            });
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
                app.UseSwagger();
                app.UseSwaggerUI(c => c.SwaggerEndpoint("/swagger/v1/swagger.json", "WeatherForecastApi v1"));
            }
            else
            {
              app.UseExceptionHandler("/error");
    	      }

            // Capture metrics about all received HTTP requests.
            app.UseHttpMetrics();

            app.UseHttpsRedirection();
            app.UseRouting();
            app.UseAuthorization();

            string ver = Environment.GetEnvironmentVariable("VERSION") ?? "unknown";
            System.Console.WriteLine("Running: " + ver);

            app.UseEndpoints(endpoints => {
              endpoints.MapGet("/version", async context => { 
                await context.Response.WriteAsync(ver);
              });

              // endpoints.Redirect("/", "/WeatherForecast");
              endpoints.MapGet("/", async context => {
                await context.Response.WriteAsync("WeatherForecastApi - Version:" + ver);
              });

              endpoints.MapControllers();

              // Enable the /metrics page to export Prometheus metrics
              endpoints.MapMetrics();
            });
        }
    }
}
