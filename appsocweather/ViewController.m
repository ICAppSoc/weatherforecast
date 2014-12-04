//
//  ViewController.m
//  appsocweather
//
//  Created by David Harver Pollak on 01/12/14.
//  Copyright (c) 2014 David Harver Pollak. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *daysWeather;

@end

@implementation ViewController

static const int kNumberOfSections = 1;
static NSString *const kCellIdentifier = @"DayWeatherIdentifier";

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellIdentifier];
    
    [self downloadWeatherForecast];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Accessors

- (NSMutableArray *)daysWeather {
    if (_daysWeather == nil) {
        _daysWeather = [NSMutableArray array];
    }
    
    return _daysWeather;
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return kNumberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.daysWeather.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifier];
    }
    
    NSDictionary *dayWeather = self.daysWeather[indexPath.row];
    [cell.textLabel setText:[NSString stringWithFormat:@"%@, %@", dayWeather[@"name"], dayWeather[@"forecast"][@"weather"][0][@"main"]]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *dayWeather = self.daysWeather[indexPath.row];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:dayWeather[@"name"]
                                                    message:[NSString stringWithFormat:@"Day temperature: %@°C\nNight temperature: %@°C\nHumidity: %@", dayWeather[@"forecast"][@"temp"][@"day"], dayWeather[@"forecast"][@"temp"][@"night"], dayWeather[@"forecast"][@"humidity"]]
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil, nil];
    [alert show];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Web Service

- (void)downloadWeatherForecast {
    // constant representing the number of seconds in a day
    const int kSecondsInDay = 60 * 60 * 24;
    
    // the url of the weather api
    NSString *const kWeatherForecastURL = @"http://api.openweathermap.org/data/2.5/forecast/daily?q=London&mode=json&units=metric&cnt=14";
    
    // create a url request for the weather api url
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:kWeatherForecastURL]];
    
    // send the request without blocking the main ui thread
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               // exit if there is a connection error
                               if (connectionError) {
                                   return;
                               }
                               
                               NSError *error;
                               // parse the json response
                               NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                                                    options:0
                                                                                      error:&error];
                               // if there was a parsing error (invalid json) then exit
                               if (error) {
                                   return;
                               }
                               
                               // date formatter to get the day name from a date
                               NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                               [dateFormatter setDateFormat:@"EEEE"];
                               
                               // for each weather forecast store the day
                               for (int i = 0; i < [json[@"list"] count]; i++) {
                                   NSMutableDictionary *dayInfo = [NSMutableDictionary dictionary];
                                   
                                   dayInfo[@"name"] = [dateFormatter stringFromDate:[[NSDate date] dateByAddingTimeInterval: kSecondsInDay * i]];
                                   dayInfo[@"forecast"] = json[@"list"][i];
                                   
                                   [self.daysWeather addObject:dayInfo];
                               }
                               
                               // refresh the content of the table view
                               [self.tableView reloadData];
                               
                           }];
}

@end
