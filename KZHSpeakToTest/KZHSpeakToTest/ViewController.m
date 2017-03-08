//
//  ViewController.m
//  KZHSpeakToTest
//
//  Created by 邝子涵 on 2017/3/8.
//  Copyright © 2017年 邝子涵. All rights reserved.
//

#import "ViewController.h"
#import <Speech/Speech.h>
@interface ViewController (){
    SFSpeechRecognizer *_speechRecognizer;                      // 语音识别器
    SFSpeechAudioBufferRecognitionRequest *_recognizerRequest;  // 音频流请求对象
    SFSpeechRecognitionTask *_recognizerTask;                   // 任务对象
    AVAudioEngine *_audioEngine;                                // 音频引擎
    
}


@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *button;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 语音识别
    // Speech框架
    // 发布时间 2016/9/19
    // 环境要求 iOS 10及以上版本
    
    // 可用语言环境
//    NSArray *localeArr = [NSLocale availableLocaleIdentifiers];
//    NSLog(@"%@", localeArr);
    
    
    // 1. 注册麦克、音频识别权限
    // Privacy - Speech Recognition Usage Description       麦克风权限
    // Privacy - Microphone Usage Description               语音识别权限
    
    
    // 2. 初始化 语音识别器&音频引擎
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:@"zh_Hans_CN"];         // 创建语言环境(汉语)
    _speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:locale];         // 语音识别器
    _audioEngine = [[AVAudioEngine alloc] init];                                    // 音频引擎
    
    
    // 3.申请授权
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        // 用户授权语音识别
        if (status == SFSpeechRecognizerAuthorizationStatusAuthorized) {
            NSLog(@"授权成功");
        }else{
            NSLog(@"授权失败");
        }
    }];
}

// 4.触发方法
- (IBAction)buttonClik:(UIButton *)sender {
    // 音频引擎在启动(触发停止)
    if (_audioEngine.isRunning) {
        [_audioEngine stop];            // 音频引擎停止
        [_recognizerRequest endAudio];  // 语音识别器停止
    }
    // 不在启动时 触发开始
    else {
        
        [sender setTitle:@"点击停止识别" forState:UIControlStateNormal];
        
        [self startRecording];
    }
}

// 5.语音识别实现
- (void)startRecording {
    // 全局音频回话
    AVAudioSession *session = [AVAudioSession sharedInstance];
    // 这个类别会静止其他应用的音频回放（比如iPod应用的音频回放）。你可以使用AVAudioPlayer的prepareToPlay和play方法，在你的应用中播放声音。主UI界面会照常工作。这时，即使屏幕被锁定或者设备为静音模式，音频回放都会继续。
    [session setCategory:AVAudioSessionCategoryRecord error:nil]; // 设置录音会话类型
    [session setMode:AVAudioSessionModeMeasurement error:nil];    // 用于检测的音频模式
    
    // 初始化音频流识别请求对象
    _recognizerRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    
    // 音频输入节点
    AVAudioInputNode *inputNode = _audioEngine.inputNode;
    
    // 音频格式
    AVAudioFormat *recordingFormat = [inputNode outputFormatForBus:0];
    
    // 持续处理输入节点收纳的音频 当音频引擎启动时 block中的回调开始执行
    // 参数 bus音频对应总线 bufferSize缓冲区与大小 format音频格式
    [inputNode installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        // 音频流识别请求对象持续增加缓冲
        [_recognizerRequest appendAudioPCMBuffer:buffer];
    }];
    
    
    // 启动音频引擎
    [_audioEngine startAndReturnError:nil];
    
    _textView.text = @"快说话啊,墨迹啥啊";
    
    
    
    // 以上内容为音频的准备工作 开启录音将录制内容保存到音频流识别请求对象中
    // 下面是识别语音内容的实现
    
    
    // 语音识别到结果的回调处理
    // 当音频流识别请求对象增加缓冲, 并得到新返回值时进入下面的回调
    // 当任务开始, 结束时也会进入下面的回调
    _recognizerTask = [_speechRecognizer recognitionTaskWithRequest:_recognizerRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        
        if (result) {
            NSLog(@"%@", [result bestTranscription].formattedString);
            // 得到识别结果赋值显示
            _textView.text = [result bestTranscription].formattedString;
        }
        
        // 任务结束或失败, 将相关对象停止工作, 置空, 还原
        if (error || result.isFinal) {
            [_audioEngine stop];                // 关闭音频引擎
            [inputNode removeTapOnBus:0];       // 移除音频输出节点
            _recognizerRequest = nil;           // 音频流请求对象制空
            _recognizerTask = nil;              // 任务对象制空
            
            [_button setTitle:@"点击开始识别" forState:UIControlStateNormal];
            _textView.text = @"####################";
        }
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
