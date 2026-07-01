#import "HangoDenyListViewController.h"
#import "HangoContact.h"
#import "HangoDataStore.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "Masonry.h"

@implementation HangoDenyListViewController {
    UICollectionView *_collectionView;
    UIView *_emptyView;
    NSArray<HangoContact *> *_denyList;
}

- (void)setupUI {
    self.showsBackButton = YES;

    UILabel *title = [[UILabel alloc] init];
    title.text = @"Deny List";
    UIFontDescriptor *descriptor = [[UIFont boldSystemFontOfSize:22].fontDescriptor
        fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic];
    title.font = [UIFont fontWithDescriptor:descriptor size:22];
    title.textAlignment = NSTextAlignmentCenter;
    title.textColor = [HangoTheme primaryDarkColor];
    [self.contentView addSubview:title];

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumInteritemSpacing = 12;
    layout.minimumLineSpacing = 16;
    layout.sectionInset = UIEdgeInsetsMake(8, 16, 16, 16);

    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _collectionView.backgroundColor = UIColor.clearColor;
    _collectionView.dataSource = (id<UICollectionViewDataSource>)self;
    _collectionView.delegate = (id<UICollectionViewDelegateFlowLayout>)self;
    [_collectionView registerClass:UICollectionViewCell.class forCellWithReuseIdentifier:@"cell"];
    [self.contentView addSubview:_collectionView];

    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(8);
        make.centerX.equalTo(self.contentView);
    }];
    [_collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(title.mas_bottom).offset(16);
        make.left.right.bottom.equalTo(self.contentView);
    }];

    _emptyView = [[UIView alloc] init];
    _emptyView.hidden = YES;
    [self.contentView addSubview:_emptyView];

    UIImageView *emptyImage = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:@"空数据图"]];
    emptyImage.contentMode = UIViewContentModeScaleAspectFit;
    [_emptyView addSubview:emptyImage];

    UILabel *emptyLabel = [[UILabel alloc] init];
    emptyLabel.text = @"There is no content here.";
    emptyLabel.font = [HangoTheme monoFont];
    emptyLabel.textColor = [HangoTheme primaryDarkColor];
    emptyLabel.textAlignment = NSTextAlignmentCenter;
    emptyLabel.numberOfLines = 0;
    [_emptyView addSubview:emptyLabel];

    [_emptyView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.contentView);
        make.centerX.equalTo(self.contentView);
        make.centerY.equalTo(self.contentView).offset(-70);
    }];
    [emptyImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.centerX.equalTo(_emptyView);
        make.width.mas_equalTo(220);
        make.height.mas_equalTo(180);
    }];
    [emptyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(emptyImage.mas_bottom).offset(16);
        make.left.right.equalTo(_emptyView).inset(32);
        make.bottom.equalTo(_emptyView);
    }];

    [self loadDenyList];
}

- (void)loadDenyList {
    _denyList = [[HangoDataStore shared] deniedContacts];
    BOOL isEmpty = _denyList.count == 0;
    _emptyView.hidden = !isEmpty;
    _collectionView.hidden = isEmpty;
    [_collectionView reloadData];
}

#pragma mark - UICollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _denyList.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = (CGRectGetWidth(collectionView.bounds) - 16 * 2 - 12) / 2.0;
    return CGSizeMake(width, 210);
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                           cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    for (UIView *v in cell.contentView.subviews) {
        [v removeFromSuperview];
    }

    UIView *card = [[UIView alloc] init];
    card.backgroundColor = UIColor.whiteColor;
    card.layer.cornerRadius = 24;
    [HangoDesignKit applyCardShadow:card];
    [cell.contentView addSubview:card];

    HangoContact *contact = _denyList[indexPath.item];
    UIImageView *avatar = [HangoDesignKit avatarWithName:contact.avatarName size:80 bordered:NO];
    [card addSubview:avatar];

    UILabel *name = [[UILabel alloc] init];
    name.text = contact.name;
    name.font = [HangoTheme monoFont];
    name.textAlignment = NSTextAlignmentCenter;
    name.textColor = [HangoTheme primaryDarkColor];
    [card addSubview:name];

    UIButton *removeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [removeBtn setTitle:@"Remove" forState:UIControlStateNormal];
    removeBtn.titleLabel.font = [HangoTheme monoFont];
    removeBtn.backgroundColor = [HangoTheme accentBlueColor];
    [removeBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    removeBtn.layer.cornerRadius = 22;
    removeBtn.clipsToBounds = YES;
    removeBtn.tag = indexPath.item;
    [removeBtn addTarget:self action:@selector(removeTapped:) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:removeBtn];

    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(cell.contentView);
    }];
    [avatar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(card).offset(20);
        make.centerX.equalTo(card);
        make.width.height.mas_equalTo(80);
    }];
    [name mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(avatar.mas_bottom).offset(10);
        make.left.right.equalTo(card).inset(8);
    }];
    [removeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(card).inset(14);
        make.bottom.equalTo(card).offset(-14);
        make.height.mas_equalTo(44);
    }];
    return cell;
}

- (void)removeTapped:(UIButton *)sender {
    HangoContact *contact = _denyList[sender.tag];
    NSString *message = [NSString stringWithFormat:@"Are you sure you want to remove %@ from the deny list?", contact.name];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Remove from Deny List?"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"Remove" style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action) {
        [[HangoDataStore shared] removeContactFromDenyList:contact.contactId];
        [weakSelf loadDenyList];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
