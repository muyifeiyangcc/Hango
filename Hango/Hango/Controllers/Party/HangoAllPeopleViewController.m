#import "HangoAllPeopleViewController.h"
#import "HangoParty.h"
#import "HangoContact.h"
#import "HangoDataStore.h"
#import "HangoRequestManager.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoPrivateChatViewController.h"
#import <Masonry/Masonry.h>

@implementation HangoAllPeopleViewController {
    UICollectionView *_collectionView;
    NSArray<HangoContact *> *_people;
}

- (void)setupUI {
    self.showsBackButton = YES;

    UILabel *title = [HangoDesignKit titleLabel:@"All Attendees"];
    [self.contentView addSubview:title];

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(156, 132);
    layout.minimumInteritemSpacing = 12;
    layout.minimumLineSpacing = 16;
    layout.sectionInset = UIEdgeInsetsMake(8, 16, 16, 16);

    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _collectionView.backgroundColor = UIColor.clearColor;
    _collectionView.dataSource = (id<UICollectionViewDataSource>)self;
    _collectionView.delegate = (id<UICollectionViewDelegate>)self;
    [_collectionView registerClass:UICollectionViewCell.class forCellWithReuseIdentifier:@"cell"];
    [self.contentView addSubview:_collectionView];

    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(52);
        make.left.equalTo(self.contentView).offset(20);
    }];
    [_collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(title.mas_bottom).offset(12);
        make.left.right.bottom.equalTo(self.contentView);
    }];

    [self loadPeople];
}

- (void)loadPeople {
    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view operation:^id {
        return [HangoDataStore shared].contacts;
    } completion:^(id result, NSError *error) {
        self->_people = result;
        [self->_collectionView reloadData];
    }];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _people.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    for (UIView *v in cell.contentView.subviews) [v removeFromSuperview];

    UIView *card = [HangoDesignKit cardView];
    [cell.contentView addSubview:card];

    HangoContact *contact = _people[indexPath.item];
    UIImageView *avatar = [HangoDesignKit avatarWithName:contact.avatarName size:56 bordered:YES];
    [card addSubview:avatar];

    UILabel *name = [[UILabel alloc] init];
    name.text = contact.name;
    name.font = [HangoTheme captionFont];
    name.textAlignment = NSTextAlignmentCenter;
    name.textColor = [HangoTheme primaryDarkColor];
    [card addSubview:name];

    UIButton *chat = [HangoDesignKit pillButtonWithTitle:@"Chat" style:HangoPillButtonStyleOutline];
    chat.titleLabel.font = [HangoTheme captionFont];
    chat.tag = indexPath.item;
    [chat addTarget:self action:@selector(chatTapped:) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:chat];

    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(cell.contentView);
    }];
    [avatar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(card).offset(14);
        make.centerX.equalTo(card);
        make.width.height.mas_equalTo(56);
    }];
    [name mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(avatar.mas_bottom).offset(6);
        make.left.right.equalTo(card);
    }];
    [chat mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(card).offset(-10);
        make.centerX.equalTo(card);
        make.width.mas_equalTo(72);
        make.height.mas_equalTo(30);
    }];
    return cell;
}

- (void)chatTapped:(UIButton *)sender {
    HangoContact *contact = _people[sender.tag];
    HangoPrivateChatViewController *vc = [[HangoPrivateChatViewController alloc] init];
    vc.contact = contact;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
