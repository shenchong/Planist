
//
//  LoginViewController.m
//  Planist
//
//  Created by easemob on 16/9/28.
//  Copyright © 2016年 沈冲. All rights reserved.
//

#import "LoginViewController.h"
#import "AccountSignResult.h"
#import "SetPasswordController.h"
#import "UserEntity.h"
#import "BindMobileController.h"
#import "ObjctResult.h"

@interface LoginViewController ()<UITextFieldDelegate>
{
    dispatch_source_t _timer;
}

@property (weak, nonatomic) IBOutlet UITextField *mobileInput;
@property (weak, nonatomic) IBOutlet UITextField *secretInput;
@property (weak, nonatomic) IBOutlet UIButton *login;
@property (weak, nonatomic) IBOutlet UIButton *changeLogin;
@property (weak, nonatomic) IBOutlet UIButton *wxLogin;
@property (weak, nonatomic) IBOutlet UIButton *qqLogin;
@property (weak, nonatomic) IBOutlet UIButton *wbLogin;
@property (weak, nonatomic) IBOutlet UILabel *thirdLoginlbl;
@property (weak, nonatomic) IBOutlet UIView *line;
@property (weak, nonatomic) IBOutlet UIView *line2;
@property (weak, nonatomic) IBOutlet UIView *line3;
@property (weak, nonatomic) IBOutlet UIView *line4;
@property (weak, nonatomic) IBOutlet UIButton *dismissBtn;
@property (weak, nonatomic) IBOutlet UIButton *secretSecurity;
@property (weak, nonatomic) IBOutlet UIButton *getCode;
@property (nonatomic, weak) UIImageView *imgVw;
@property (nonatomic, assign) BOOL isNew;

@property (nonatomic, assign) BOOL isSecurity;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.view setBackgroundColor:[UIColor whiteColor]];
//    [self initViews];
    [self setupViews];
    
    //监听文本框
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeText) name:UITextFieldTextDidChangeNotification object:self.mobileInput];
}

- (void)setupViews{
    self.login.layer.cornerRadius = 6;
    self.login.layer.masksToBounds = YES;
    self.login.backgroundColor = RGBColor(250, 100, 100, 1);
    self.login.adjustsImageWhenHighlighted = NO;
    [self.login addTarget:self action:@selector(loginAction) forControlEvents:UIControlEventTouchUpInside];
    
    self.line.backgroundColor = self.line2.backgroundColor = self.line3.backgroundColor = self.line4.backgroundColor = RGBColor(216, 216, 216, 1);
    
    self.mobileInput.delegate = self;
    self.secretInput.delegate = self;
    
    self.isSecurity = YES;
    self.secretSecurity.adjustsImageWhenHighlighted = NO;
    [self.secretSecurity addTarget:self action:@selector(securitySwitch:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.dismissBtn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    self.dismissBtn.adjustsImageWhenHighlighted = NO;
    
    self.changeLogin.adjustsImageWhenHighlighted = NO;
    [self.changeLogin addTarget:self action:@selector(changeLogin:) forControlEvents:UIControlEventTouchUpInside];
    
    self.getCode.layer.cornerRadius = 4;
    self.getCode.layer.masksToBounds = YES;
    [self.getCode setBackgroundColor:RGBColor(216, 216, 216, 1)];
    self.getCode.userInteractionEnabled = NO;
    [self.getCode addTarget:self action:@selector(getCodeAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [_qqLogin addTarget:self action:@selector(QQLogin) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - UI
- (void)securitySwitch:(UIButton *)sender{
    
    if (self.isSecurity) {
        [self.secretSecurity setBackgroundImage:[UIImage imageNamed:@"密码可见图标"] forState:UIControlStateNormal];
        self.secretInput.secureTextEntry = NO;
        self.isSecurity = NO;
    }else{
        [self.secretSecurity setBackgroundImage:[UIImage imageNamed:@"密码不可见图标"] forState:UIControlStateNormal];
        self.secretInput.secureTextEntry = YES;
        self.isSecurity = YES;
    }
}

- (void)changeLogin:(UIButton *)sender{
    if ([self.changeLogin.titleLabel.text isEqualToString:@"使用验证码登录"]) {
        [self.changeLogin setTitle:@"使用密码登录" forState:UIControlStateNormal];
        self.secretInput.width = 180;
        self.secretSecurity.hidden = YES;
        self.getCode.hidden = NO;
        self.secretInput.placeholder = @"输入验证码";
        self.secretInput.text = nil;
        self.secretInput.secureTextEntry = NO;
        
    }else if ([self.changeLogin.titleLabel.text isEqualToString:@"使用密码登录"]){
        [self.changeLogin setTitle:@"使用验证码登录" forState:UIControlStateNormal];
        self.secretInput.width = 210;
        self.secretSecurity.hidden = NO;
        self.getCode.hidden = YES;
        self.secretInput.placeholder = @"输入密码";
        self.secretInput.text = nil;
        self.secretInput.secureTextEntry = self.isSecurity;
    }
}

#pragma mark - Login
- (void)loginAction{
    if (self.mobileInput.text.length == 11&&self.secretInput.text.length != 0) {
        if ([self.changeLogin.titleLabel.text isEqualToString:@"使用密码登录"]) {
            NSString *phoneNumber = self.mobileInput.text;
            NSString *urlStrTemp = [NSString stringWithFormat:@"%@?phone=%@&passwordPhone=%@",API_Account_LoginByPhone,phoneNumber,self.secretInput.text];
            NSString *urlStr = [urlStrTemp stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            
            [WebAPIClient getJSONWithUrl:urlStr parameters:nil success:^(id result) {
                NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:result options:NSJSONReadingMutableContainers error:nil];
                NSLog(@"%@",dic);
                
                ObjctResult *account = [UserEntity GetCurrentAccount];
                
                AccountSignResult *signResult = [AccountSignResult mj_objectWithKeyValues:dic];
                account.userinfo.phone = signResult.obj.userinfo.phone = phoneNumber;
                account.token = signResult.obj.token;
                if (account) {
                    [UserEntity SaveCurrentAccount:account];
                }else{
                    [UserEntity SaveCurrentAccount:signResult.obj];
                    account = [UserEntity GetCurrentAccount];
                }
                
                
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                
                if (account.isNew) {
                    SetPasswordController *newPassVC = [[SetPasswordController alloc]init];
                    [self presentViewController:newPassVC animated:YES completion:nil];
                }else{
                    NSString *msg = [dic objectForKey:@"msg"];
                    [MBProgressHUD showTextHUDAddedTo:self.view withText:msg detailText:nil andHideAfterDelay:1];
                    [self performSelector:@selector(back) withObject:nil afterDelay:1];
                }

            } fail:^(NSError *error) {
                NSLog(@"error=%@",error);
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            }];
        }else if ([self.changeLogin.titleLabel.text isEqualToString:@"使用验证码登录"]){
            NSString *phoneNumber = self.mobileInput.text;
            NSString *urlStrTemp = [NSString stringWithFormat:@"%@?phone=%@&password=%@",API_Account_LoginByPassword,phoneNumber,self.secretInput.text];
            NSString *urlStr = [urlStrTemp stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            
            [WebAPIClient getJSONWithUrl:urlStr parameters:nil success:^(id result) {
                
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                
                NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:result options:NSJSONReadingMutableContainers error:nil];
                NSLog(@"%@",dic);
                
                ObjctResult *account = [UserEntity GetCurrentAccount];
                
                AccountSignResult *signResult = [AccountSignResult mj_objectWithKeyValues:dic];
                account.userinfo.domicile = signResult.obj.userinfo.domicile = [signResult.obj.userinfo.domicile stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                account.userinfo.phone = signResult.obj.userinfo.phone = self.mobileInput.text;
                account.token = signResult.obj.token;
                
                if (account) {
                    [UserEntity SaveCurrentAccount:account];
                }else{
                    [UserEntity SaveCurrentAccount:signResult.obj];
                }
                
                
                
                NSString *msg = signResult.msg;
                [MBProgressHUD showTextHUDAddedTo:self.view withText:msg detailText:nil andHideAfterDelay:1];
                [self performSelector:@selector(back) withObject:nil afterDelay:1];
                
            } fail:^(NSError *error) {
                NSLog(@"error=%@",error);
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            }];
        }
    }
    
    if (self.mobileInput.text.length == 0) {
        [MBProgressHUD showTextHUDAddedTo:self.view withText:@"请输入手机号" detailText:nil andHideAfterDelay:1];

    }else if (self.mobileInput.text.length != 11){
        NSLog(@"请输入正确的手机号");
        [MBProgressHUD showTextHUDAddedTo:self.view withText:@"请输入正确手机号" detailText:nil andHideAfterDelay:1];
    }else if (self.mobileInput.text.length == 11){
        if ([self.changeLogin.titleLabel.text isEqualToString:@"使用验证码登录"]) {
            if (self.secretInput.text.length != 6) {
//                [MBProgressHUD showTextHUDAddedTo:self.view withText:@"请输入验证码" detailText:nil andHideAfterDelay:1];
            }
        }
    }
}

- (void)QQLogin{
    id <ALBBLoginService> loginService = [[ALBBSDK sharedInstance] getService:@protocol(ALBBLoginService)];
    [loginService showLogin:self successCallback:^(TaeSession *session) {

        NSLog(@"session===%@",session);
        
        TaeSessionModel *taeModel = [[TaeSessionModel alloc]init];
        taeModel.userId = [session getUserId];
        taeModel.authorizationCode = [session getAuthorizationCode];
        taeModel.topAccessToken = [session getTopAccessToken];
        taeModel.sessionId = [session getSessionId];
        [UserEntity SaveTaeSession:taeModel];
        
        BindMobileController *bindPhoneVC = [[BindMobileController alloc]init];
        [self presentViewController:bindPhoneVC animated:YES completion:nil];
        
    } failedCallback:^(NSError *error){

    }];
}


- (void)getCodeAction:(UIButton *)sender{
    [self startTime];
    
    NSString *phoneNumber = self.mobileInput.text;
    NSString *urlStrTemp = [NSString stringWithFormat:@"%@?phone=%@&type=%@",API_Account_GetCode,phoneNumber,@"0"];
    NSString *urlStr = [urlStrTemp stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    [WebAPIClient getJSONWithUrl:urlStr parameters:nil success:^(id result) {
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:result options:NSJSONReadingMutableContainers error:nil];
        NSLog(@"%@",dic);
        
        AccountSignResult *signResult = [AccountSignResult mj_objectWithKeyValues:dic];
        [UserEntity SaveCurrentAccount:signResult.obj];
        ObjctResult *srt = [UserEntity GetCurrentAccount];
        NSLog(@"signResult.msg==%@",signResult.msg);
        NSLog(@"srt==%d",srt.isNew);
        
        [MBProgressHUD showTextHUDAddedTo:self.view withText:@"验证码已发送" detailText:@"请耐心等待" andHideAfterDelay:1];
        
    } fail:^(NSError *error) {
        NSLog(@"%@",error);
        [MBProgressHUD showTextHUDAddedTo:self.view withText:@"发送验证码失败" detailText:nil andHideAfterDelay:1];
    }];
}

- (void)startTime
{
    __block int timeout=60; //倒计时时间
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,queue);
    dispatch_source_set_timer(_timer,dispatch_walltime(NULL, 0),1.0*NSEC_PER_SEC, 0); //每秒执行
    dispatch_source_set_event_handler(_timer, ^{
        if(timeout<=0){ //倒计时结束，关闭
            [self endTimer];
        }else{
            //int minutes = timeout / 60;
            int seconds = timeout %61;
            NSString *strTime = [NSString stringWithFormat:@"%.2d", seconds];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.getCode.userInteractionEnabled = NO;
                [self.getCode setTitle:[NSString stringWithFormat:@"%@后重发",strTime] forState:UIControlStateNormal];
                [self.getCode setBackgroundColor:RGBColor(216, 216, 216, 1)];
                
            });
            timeout--;
        }
    });
    dispatch_resume(_timer);
}

- (void)endTimer
{
    dispatch_source_cancel(_timer);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.getCode.userInteractionEnabled = YES;
        [self.getCode setTitle:@"获取验证码" forState:UIControlStateNormal];
        [self.getCode setBackgroundColor:RGBColor(250, 100, 100, 1)];
    });
    
}

#pragma mark - UITextField Delegate
- (void)changeText{
    if (self.mobileInput) {
        if (self.mobileInput.text.length == 11) {
            self.getCode.userInteractionEnabled = YES;
            [self.getCode setBackgroundColor:RGBColor(250, 100, 100, 1)];
        }else if(self.mobileInput.text.length != 11){
            self.getCode.userInteractionEnabled = NO;
            [self.getCode setBackgroundColor:RGBColor(216, 216, 216, 1)];
        }
    }
}

- (void)back{
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
