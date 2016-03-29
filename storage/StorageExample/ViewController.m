//
//  Copyright (c) 2016 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

@import Photos;
#import "ViewController.h"
#import "DownloadViewController.h"

#import "FirebaseStorage.h"
@import Firebase.Auth;

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *takePicButton;
@property (weak, nonatomic) IBOutlet UIButton *downloadPicButton;
@property (weak, nonatomic) IBOutlet UITextView *urlTextView;

@property (strong, nonatomic) FIRStorageReference *storageRef;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  // [START configurestorage]
  FIRFirebaseApp *app = [FIRFirebaseApp app];
  self.storageRef = [[FIRStorage storageForApp:app] reference];
  // [END configurestorage]

  // [START storageauth]
  // Using Firebase Storage requires the user be authenticated. Here we are using
  // anonymous authentication.
  if (![FIRAuth auth].currentUser) {
    [[FIRAuth auth] signInAnonymouslyWithCallback:^(FIRUser * _Nullable user, NSError * _Nullable error) {
      if (error) {
        _urlTextView.text = error.description;
        _takePicButton.enabled = NO;
        _downloadPicButton.enabled = NO;
      } else {
        _takePicButton.enabled = YES;
        _downloadPicButton.enabled = YES;
        _urlTextView.text = @"";
      }
    }];
  }
  // [END storageauth]
}

# pragma mark - Image Picker

- (IBAction)didTapTakePicture:(id)sender {
  UIImagePickerController * picker = [[UIImagePickerController alloc] init];
  picker.delegate = self;
  if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
  } else {
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  }

  [self presentViewController:picker animated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker
    didFinishPickingMediaWithInfo:(NSDictionary *)info {
  [picker dismissViewControllerAnimated:YES completion:NULL];

  _urlTextView.text = @"Beginning Upload";
  NSURL *referenceUrl = info[UIImagePickerControllerReferenceURL];
  PHFetchResult* assets = [PHAsset fetchAssetsWithALAssetURLs:@[referenceUrl] options:nil];
  PHAsset *asset = [assets firstObject];
  [asset requestContentEditingInputWithOptions:nil
                             completionHandler:^(PHContentEditingInput *contentEditingInput, NSDictionary *info) {
                               NSString *imageFile = [contentEditingInput.fullSizeImageURL absoluteString];
                               NSString *filePath =
                                   [NSString stringWithFormat:@"%@/%lld/%@",
                                       [FIRAuth auth].currentUser.uid,
                                       (long long)([[NSDate date] timeIntervalSince1970] * 1000.0),
                                       [referenceUrl lastPathComponent]];
                               // [START uploadimage]
                               FIRStorageMetadata *metadata = [FIRStorageMetadata new];
                               metadata.contentType = @"image/jpeg";
                               [[_storageRef childByAppendingPath:filePath]
                                putFile:imageFile metadata:metadata
                                withCompletion:^(FIRStorageMetadata *metadata, NSError *error) {
                                  if (error) {
                                    NSLog(@"Error uploading: %@", error);
                                    _urlTextView.text = @"Upload Failed";
                                    return;
                                  }
                                  NSLog(@"Upload Succeeded!");
                                  _urlTextView.text = [metadata.downloadURL absoluteString];
                                }];
                               // [END uploadimage]
                             }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [picker dismissViewControllerAnimated:YES completion:NULL];
}


@end