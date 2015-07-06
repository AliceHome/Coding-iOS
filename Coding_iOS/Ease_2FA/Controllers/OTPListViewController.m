//
//  OTPListViewController.m
//  Coding_iOS
//
//  Created by Ease on 15/7/2.
//  Copyright (c) 2015年 Coding. All rights reserved.
//

#import "OTPListViewController.h"
#import "ZXScanCodeViewController.h"
#import "OTPTableViewCell.h"

#import "OTPAuthURL.h"
#import <SSKeychain/SSKeychain.h>

static NSString *const kOTPKeychainEntriesArray = @"OTPKeychainEntries";

@interface OTPListViewController ()<UITableViewDataSource, UITableViewDelegate>

//Welcome
@property (strong, nonatomic) UIImageView *tipImageView;
@property (strong, nonatomic) UILabel *tipLabel;
@property (strong, nonatomic) UIButton *beginButton;

//Data List
@property (strong, nonatomic) UITableView *myTableView;

//Data
@property (nonatomic, strong) NSMutableArray *authURLs;

@end

@implementation OTPListViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    self.title = @"身份验证器";
    [self loadKeychainArray];
}

- (void)loadKeychainArray{
    NSArray *otpAccountDictList = [SSKeychain accountsForService:kOTPService];
    self.authURLs = [NSMutableArray arrayWithCapacity:[otpAccountDictList count]];
    for (NSDictionary *otpAccountDict in otpAccountDictList) {
        OTPAuthURL *authURL = [OTPAuthURL ease_authURLWithKeychainDictionary:otpAccountDict];
        if (authURL) {
            [self.authURLs addObject:authURL];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self configUI];
}

#pragma mark p_M

- (void)configUI{
    if (self.authURLs.count > 0) {
        
        [self.tipImageView removeFromSuperview];
        self.tipImageView = nil;

        [self.tipLabel removeFromSuperview];
        self.tipLabel = nil;
        
        [self.beginButton removeFromSuperview];
        self.beginButton = nil;
        
        if (!_myTableView) {
            //    添加myTableView
            _myTableView = ({
                UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
                tableView.backgroundColor = kColorTableSectionBg;
                tableView.dataSource = self;
                tableView.delegate = self;
                tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
                [tableView registerClass:[TOTPTableViewCell class] forCellReuseIdentifier:NSStringFromClass([TOTPAuthURL class])];
                [tableView registerClass:[HOTPTableViewCell class] forCellReuseIdentifier:NSStringFromClass([HOTPAuthURL class])];
                [self.view addSubview:tableView];
                [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.edges.equalTo(self.view);
                }];
                tableView;
            });
            [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"addBtn_Nav"] style:UIBarButtonItemStylePlain target:self action:@selector(beginButtonClicked:)] animated:YES];
        }
        [self.myTableView reloadData];
    }else{
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
        [self.myTableView removeFromSuperview];
        self.myTableView = nil;
        
        if (!_tipImageView) {
            _tipImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tip_2FA"]];
            [self.view addSubview:_tipImageView];
        }
        if (!_tipLabel) {
            _tipLabel = [UILabel new];
            _tipLabel.numberOfLines = 0;
            _tipLabel.textAlignment = NSTextAlignmentCenter;
            _tipLabel.font = [UIFont systemFontOfSize:16];
            _tipLabel.textColor = [UIColor colorWithHexString:@"0x222222"];
            _tipLabel.text = @"Coding 两步验证指的是用户登录账户的时候，除了要输入用户名和密码，还要求用户输入一个手机生成的动态密码，为帐户额外添加了一层保护，即使入侵者窃取了用户的密码，也会因不能使用用户的手机而无法登录帐户。";
            [self.view addSubview:_tipLabel];
        }
        if (!_beginButton) {
            _beginButton = [UIButton buttonWithStyle:StrapSuccessStyle andTitle:@"开始验证" andFrame:CGRectMake(kPaddingLeftWidth, CGRectGetHeight(self.view.frame)- 20 - 45, kScreen_Width-kPaddingLeftWidth*2, 45) target:self action:@selector(beginButtonClicked:)];
            [self.view addSubview:_beginButton];
        }
        [_tipImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.view);
            make.top.mas_equalTo(kScreen_Height/6);
        }];
        [_tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.view);
            make.top.equalTo(_tipImageView.mas_bottom).offset(40);
            make.left.equalTo(self.view).offset(kPaddingLeftWidth);
            make.right.equalTo(self.view).offset(-kPaddingLeftWidth);
        }];
    }
}

- (void)beginButtonClicked:(id)sender{
    __weak typeof(self) weakSelf = self;
    ZXScanCodeViewController *vc = [ZXScanCodeViewController new];
    vc.sucessScanBlock = ^(OTPAuthURL *authURL){
        [weakSelf addOneAuthURL:authURL];
    };
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)addOneAuthURL:(OTPAuthURL *)authURL{
    [authURL saveToKeychain];
    [self.authURLs addObject:authURL];
    [self configUI];
}

#pragma mark table_M
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return [self.authURLs count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellIdentifier = nil;
    OTPAuthURL *authURL = self.authURLs[indexPath.section];
    if ([authURL isKindOfClass:[TOTPAuthURL class]]) {
        cellIdentifier = NSStringFromClass([TOTPAuthURL class]);
    }else{
        cellIdentifier = NSStringFromClass([HOTPAuthURL class]);
    }
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    [(OTPTableViewCell *)cell setAuthURL:authURL];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [OTPTableViewCell cellHeight];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return kScaleFrom_iPhone5_Desgin(20);
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0.5;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    OTPAuthURL *authURL = self.authURLs[indexPath.section];
    if (authURL.otpCode.length > 0) {
        [[UIPasteboard generalPasteboard] setString:authURL.otpCode];
        [self showHudTipStr:@"已复制"];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        OTPAuthURL *authURL = self.authURLs[indexPath.section];
        [self.authURLs removeObject:authURL];
        [authURL removeFromKeychain];
        [self configUI];
    }
}

@end