//
//  ServiceViewController.m
//  wifi通讯
//
//  Created by 晓坤张 on 2017/8/12.
//  Copyright © 2017年 晓坤张. All rights reserved.
//

#import "ServiceViewController.h"

#import "GCDAsyncSocket.h"

#import "WIFITools.h"

@interface ServiceViewController ()<UITableViewDelegate,UITableViewDataSource>

//显示wifi名称文本
@property (weak, nonatomic) IBOutlet UILabel *wifiNameLabel;

//显示ip地址文本
@property (weak, nonatomic) IBOutlet UILabel *ipAddressLabel;

//开始连接按钮（监听端口）
@property (weak, nonatomic) IBOutlet UIButton *wifiButton;

//服务端socket（在socket网络通讯中，万物皆socket，类似于OC中的NSObject）
@property(nonatomic,strong)GCDAsyncSocket *serviceSocket;

//客户端数组(防止因为客户端是局部变量而被释放！)
@property(nonatomic,strong)NSMutableArray *clientArr;

//显示所有客户端的数据
@property (weak, nonatomic) IBOutlet UITableView *tableView;
//存放客户端的消息用于显示
@property(nonatomic,strong)NSMutableArray <NSData *>*tableArr;

@end

@implementation ServiceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //界面初始化操作
    self.wifiNameLabel.text = [NSString stringWithFormat:@"wifi名称:%@",[WIFITools currentWifiSSID]];
    self.ipAddressLabel.text = [NSString stringWithFormat:@"ip地址:%@",[WIFITools localWiFiIPAddress]];
    
    self.tableArr = [NSMutableArray array];
    // Do any additional setup after loading the view.
}

//服务端监听按钮点击事件
- (IBAction)wifiButtonClick:(UIButton*)sender {
    
    //1.创建服务端socket
    if (!self.serviceSocket) {
        self.serviceSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    
    NSError *error = nil;
    
    //2.开始监听端口
    //注意：笔者这里随便写的一个端口。实际开发中，端口号不能随便乱写，硬件工程师会给我们一份wifi通讯协议文档，文档中会写明服务端的ip地址及端口号。  我这里默认情况下，ip地址用的就是mac电脑当前连接wifi的ip地址，已经在界面初始化时获取，端口号我写的是1234.
    [self.serviceSocket acceptOnPort:1234 error:&error];
    
    if (error==nil) {
        NSLog(@"监听成功");
    }
    else
    {
        NSLog(@"%@",error.description);
    }
    
}


#pragma mark - GCDAsyncSocketDelegate
//服务端监听到客户端的连接
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    //1.将连接的客户端添加到数组,防止局部变量被释放
    if (!self.clientArr) {
        self.clientArr = [NSMutableArray array];
    }
    [self.clientArr addObject:newSocket];
    
    //2给客户端发送一个消息，可以让客户端在连接服务端时快速知道自己是否连接服务端成功
    //注意：有的wifi通讯在这里会有一个握手的过程，也就是服务端会发给客户端一个用于验证的密文，然后客户端验证通过之后才能继续通讯，否则服务端就会踢掉客户端。主要是保证只能让自己的APP连接自己的产品，防止被其他程序连接
    NSString *str = @"服务器:欢迎来到黑马程序员";
    
    //线程延迟发送消息，防止线程阻塞
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [newSocket writeData:[str dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
    });
    
    
    //2.开始读取客户端的数据（类似于服务器实时监听客户端发送的数据）
    //注意：该行代码调用一次只能接收一次数据
    [newSocket readDataWithTimeout:-1 tag:0];
}

//服务端接收数据成功
-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"服务端接发送数据:%@",str);
    //添加到数组用于界面显示
    [self.tableArr addObject:data];
    //1.服务器的作用主要是数据的转发，所以这里我们将数据转发给其他客户端
    for (GCDAsyncSocket *socket in self.clientArr) {
        //1.1过滤掉发送消息者本身
        if (socket != sock) {
            
            //1.2给客户端发送数据
            [socket writeData:data withTimeout:-1 tag:0];
        }
    }
    [self.tableView reloadData];
    
    //2.接收到客户端数据之后，继续读取客户端数据
    //注意在这个方法中调用该方法可以保证一直都能读取到客户端数据，如果不调用，每一个客户端的数据就只能读取一次
    [sock readDataWithTimeout:-1 tag:0];
    
}

//服务端发送数据成功
-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"服务端发送数据");
}

#pragma mark -UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"serviceCell"];
    
    UILabel *nameLabel = (UILabel *)[cell.contentView viewWithTag:1];
    UILabel *msgLabel = (UILabel *)[cell.contentView viewWithTag:2];
    
    //读取数据  笔者这里定义的数据协议格式是这样   客户端的设备名称:数据   通过分割：来获取对于数据，实际中应当根据wifi协议来。另外，笔者这里演示的字符串通讯，实际中wifi协议有可能是更加底层的一些通讯格式  例如 二进制字节流  Ascii码等
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
