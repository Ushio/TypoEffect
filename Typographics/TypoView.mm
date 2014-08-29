//
//  TypoView.m
//  Typographics
//
//  Created by yoshimura atsushi on 2014/08/29.
//  Copyright (c) 2014年 wow. All rights reserved.
//

#import "TypoView.h"

// Objective-C
#import <CoreText/CoreText.h>

// CPP
#include <vector>
#include <array>
#include <memory>
#include <limits>

namespace
{
    template <typename T>
    using cf_shared_ptr = std::shared_ptr<typename std::remove_pointer<T>::type>;
    
    cf_shared_ptr<CGPathRef> path_from_line(cf_shared_ptr<CTLineRef> aLine)
    {
        cf_shared_ptr<CGMutablePathRef> path(CGPathCreateMutable(), CGPathRelease);
    
        CFArrayRef runs = CTLineGetGlyphRuns(aLine.get());
        CFIndex runCount = CFArrayGetCount(runs);
        for(int iRun = 0; iRun < runCount ; ++iRun)
        {
            CTRunRef run = (CTRunRef)CFArrayGetValueAtIndex(runs, iRun);
            
            CTFontRef runFont = (CTFontRef)CFDictionaryGetValue(CTRunGetAttributes(run), kCTFontAttributeName);
            CFIndex glyphCount = CTRunGetGlyphCount(run);
            const CGGlyph *glyphs = CTRunGetGlyphsPtr(run);
            const CGPoint *positions = CTRunGetPositionsPtr(run);
            
            for(int iGlyph = 0 ; iGlyph < glyphCount ; ++iGlyph)
            {
                CGAffineTransform transform = CGAffineTransformMakeTranslation(positions[iGlyph].x, positions[iGlyph].y);
                CGPathRef glyphPath = CTFontCreatePathForGlyph(runFont, glyphs[iGlyph], NULL);
                CGPathAddPath(path.get(), &transform, glyphPath);
                CGPathRelease(glyphPath);
            }
        }
        return path;
    }
}
@implementation TypoView
{
    IBOutlet UISlider *_slider;
    cf_shared_ptr<CGPathRef> _textPath;
}

- (void)awakeFromNib
{
    NSString *text = @"Typographics";
    
    cf_shared_ptr<CTFontRef> ctFont(CTFontCreateWithName(CFSTR("AvenirNext-MediumItalic"), 50, NULL), CFRelease);
    
    CFRange textRange = CFRangeMake(0, text.length);
    
    cf_shared_ptr<CFMutableAttributedStringRef> aText(CFAttributedStringCreateMutable(NULL, text.length), CFRelease);
    
    // テキスト
    CFAttributedStringReplaceString(aText.get(), CFRangeMake(0, 0), (CFStringRef)text);
    
    // フォント
    CFAttributedStringSetAttribute(aText.get(), textRange, kCTFontAttributeName, ctFont.get());
    
    cf_shared_ptr<CTLineRef> ctLine(CTLineCreateWithAttributedString(aText.get()), CFRelease);
    
    _textPath = path_from_line(ctLine);
}
- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    /* 数学座標系にする
     |
     |
     |x
     +-------
     */
    CGContextConcatCTM(context, CGAffineTransformMake(1, 0, 0, -1, 0, self.bounds.size.height));
    
    // 数値は決め打
    std::array<CGFloat, 2> dash = {
        static_cast<CGFloat>(_slider.value * 180.0f),
        std::numeric_limits<CGFloat>::max()
    };
    CGContextSetLineDash(context, 0, dash.data(), dash.size());

    // センタリング
    CGRect boundingBox = CGPathGetBoundingBox(_textPath.get());
    CGContextTranslateCTM(context, self.bounds.size.width * 0.5, self.bounds.size.height * 0.5);
    CGContextTranslateCTM(context, -boundingBox.size.width * 0.5, -boundingBox.size.height * 0.5);
    CGContextTranslateCTM(context, -boundingBox.origin.x, -boundingBox.origin.y);
    
    CGContextAddPath(context, _textPath.get());
    CGContextStrokePath(context);
}
- (IBAction)didChangedSlider:(UISlider *)sender
{
    [self setNeedsDisplay];
}

@end
