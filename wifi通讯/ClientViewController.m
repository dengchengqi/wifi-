//
//  ClientViewController.m
//  wifi通讯
//
//  Created by 晓坤张 on 2017/8/12.
//  Copyright © 2017年 晓坤张. All rights reserved.
//

#import "ClientViewController.h"

#import "GCDAsyncSocket.h"
#import "WIFITools.h"

@interface ClientViewController ()<GCDAsyncSocketDelegate,UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UILabel *wifiNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *ipAddressLabel;
@property (weak, nonatomic) IBOutlet UIButton *senMsgButton;

@property (weak, nonatomic) IBOutlet UIButton *clientButton;

@property(nonatomic,strong)UITextField *textField;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

//存放客户端的消息用于显示
@property(nonatomic,strong)NSMutableArray <NSData *>*tableArr;
//
//客户端socket
@property(nonatomic,strong)GCDAsyncSocket *clientSocket;
@end

@implementation ClientViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.wifiNameLabel.text = [NSString stringWithFormat:@"wifi名称:%@",[WIFITools currentWifiSSID]];
    self.ipAddressLabel.text = [NSString stringWithFormat:@"ip地址:%@",[WIFITools localWiFiIPAddress]];
    
    self.tableArr = [NSMutableArray array];
    // Do any additional setup after loading the view.
}



//客户端开始连接
- (IBAction)wifiButtonClik:(UIButton *)sender {
    
    //1.创建客户端socket
    //在socket通讯中，无论是客户端还是服务端，任何对象都是socket，类似于万物皆NSObject
    if (!self.clientSocket) {
        self.clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    
    
    NSLog(@"%@",self.clientSocket.localHost);
    
    //2.连接服务端
    //注意：此处有两个重点    1.这里的ip地址一定要是同一个局域网服务端的ip地址，端口号也要与服务端连接的端口号一致   2.实际开发中，一般服务端的ip地址和所监听的端口号都会在wifit通信协议中注明，这里只是笔者为了掩饰，所以随便写了一个端口号1234，而这里的ip地址也是笔者为了掩饰给mac电脑设置了一个固定ip地址
//    [self.clientSocket connectToHost:@"192.168.0.102" onPort:1234 error:nil];
    
      NSString * serviceSocketIp = @"10.10.10.27";
      [self.clientSocket connectToHost:serviceSocketIp onPort:1234 error:nil];
    
}



//客户端发送数据
- (IBAction)sendMsgButton:(UIButton*)sender {
    
    if (!self.textField) {
        self.textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 40)];
        self.textField.delegate = self;
        self.textField.returnKeyType = UIReturnKeySend;
        [self.view addSubview:self.textField];
        
    }
    self.textField.hidden = NO;
    [self.textField becomeFirstResponder];
    
    
}

#pragma mark- GCDAsyncSocketDelegate

//客户端连接服务端成功
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    //1.将开始连接按钮变为已连接
    [self.clientButton setTitle:@"连接成功" forState:UIControlStateNormal];
    //2.发送数据按钮开启交互
    self.senMsgButton.enabled = YES;
    
    //3.客户端开始读取服务端的数据
    [self.clientSocket readDataWithTimeout:-1 tag:0];
}



//客户端接收数据成功
-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"客户端接发送数据:%@",str);
    
    //0.添加到数据源
    [self.tableArr addObject:data];
    
    //1.刷新界面
    [self.tableView reloadData];
    //2.继续读取数据（否则只能读取一次）
    [sock readDataWithTimeout:-1 tag:0];
    
    
}

//客户端发送数据成功
-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"客户端发送数据");
    //刷新数据
    [self.tableView reloadData];
}



#pragma mark -UITextFieldDelegate  发送数据

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    //1.发送数据  具体的数据格式会由硬件工程师定义，示例这里使用冒号:将我的手机名称和消息分开
    NSString *str = [NSString stringWithFormat:@"%@:%@",[UIDevice currentDevice].name,textField.text];
    
    //2.发送数据 第一个参数：二进制数据  第二个参数：超时等待  -1为永久等待  tag：消息标签 没啥用
    [self.clientSocket writeData:[str dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:1];
    
    //3添加到数组用于显示
    [self.tableArr addObject:[str dataUsingEncoding:NSUTF8StringEncoding]];
    
    textField.text = nil;
    
    return YES;
}

#pragma mark -UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"clientCell"];
    
    UILabel *nameLabel = (UILabel *)[cell.contentView viewWithTag:1];
    UILabel *msgLabel = (UILabel *)[cell.contentView viewWithTag:2];
    
    //读取数据
    NSData *data = self.tableArr[indexPath.row];
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *arr = [str componentsSeparatedByString:@":"];
    //显示数据
    nameLabel.text = [NSString stringWithFormat:@"设备名称：%@",arr[0]];
    msgLabel.text = [NSString stringWithFormat:@" 数据：%@",arr[1]];
    
    return cell;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
