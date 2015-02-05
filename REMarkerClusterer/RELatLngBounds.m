//
// RELatLngBounds.m
// REMarkerClusterer
//
// Copyright (c) 2011-2013 Roman Efimov (https://github.com/romaonthego)
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "RELatLngBounds.h"


//#define RE_ENABLE_UNIT_TESTS

#ifdef RE_ENABLE_UNIT_TESTS
static BOOL gIsFirstTime = YES;

@interface RELatLngBounds()
- (void)runContainsTests;
@end
#endif

@implementation RELatLngBounds

- (id)initWithMapView:(MKMapView *)mapView
{
    if ((self = [super init])) {
        _mapView = mapView;
    }
    return self;
}

- (void)setSouthWest:(CLLocationCoordinate2D)sw northEast:(CLLocationCoordinate2D)ne
{
    _southWest = sw;
    _northEast = ne;
    _southEast = CLLocationCoordinate2DMake(sw.latitude, ne.longitude);
    _northWest = CLLocationCoordinate2DMake(ne.latitude, sw.longitude);
}

- (void)setExtendedBounds:(NSInteger)gridSize
{
    CLLocationCoordinate2D tr = CLLocationCoordinate2DMake(_northEast.latitude, _northEast.longitude);
    CLLocationCoordinate2D bl = CLLocationCoordinate2DMake(_southWest.latitude, _southWest.longitude);
    
    CGPoint trPix = [_mapView convertCoordinate:tr toPointToView:_mapView];
    trPix.x += gridSize;
    trPix.y -= gridSize;
    
    CGPoint blPix = [_mapView convertCoordinate:bl toPointToView:_mapView];
    blPix.x -= gridSize;
    blPix.y += gridSize;
    
    CLLocationCoordinate2D ne = [_mapView convertPoint:trPix toCoordinateFromView:_mapView];
    CLLocationCoordinate2D sw = [_mapView convertPoint:blPix toCoordinateFromView:_mapView];
    
    _northEast = ne;
    _southWest = sw;
    _southEast = CLLocationCoordinate2DMake(sw.latitude, ne.longitude);
    _northWest = CLLocationCoordinate2DMake(ne.latitude, sw.longitude);
}

- (bool)contains:(CLLocationCoordinate2D)coordinate
{
#ifdef RE_ENABLE_UNIT_TESTS
	if (gIsFirstTime) {
		gIsFirstTime = NO;
		[self runContainsTests];
	}
#endif

	if ((coordinate.latitude > _northEast.latitude) ||
		(coordinate.latitude < _southWest.latitude)) {
		return NO;	// latitude is out of bounds.
	}

	// Case 1: region does not span the 180th meridian (aka the International
	//         Date Line).
	if (_northEast.longitude >= _southWest.longitude) {
		return ((coordinate.longitude <= _northEast.longitude) &&
				(coordinate.longitude >= _southWest.longitude));
	}

	// Case 2: region spans the 180th meridian.  Check both sides.
	return (coordinate.longitude < _northEast.longitude) ||
	       (coordinate.longitude > _southWest.longitude);
}

#ifdef RE_ENABLE_UNIT_TESTS
- (void)runContainsTests
{
	typedef struct  {
		const char *tag;
		CLLocationCoordinate2D ne;
		CLLocationCoordinate2D sw;
	} REContainsLatLngBoundsInfo;

	typedef struct {
		const char *boundsTag;
		CLLocationCoordinate2D coord;
		BOOL isInBounds;
	} REContainsTest;

	REContainsLatLngBoundsInfo boundsInfoArray[] = {
		{ "Asia",          { 33.6,  141.0 }, { 33.4,  139.0 } },
		{ "NorthAmerica",  { 45.5,  -82.5 }, { 44.5,  -83.5 } },
		{ "Dateline1",     { 10.5, -179.5 }, {  9.5,  179.5 } },
		{ "Dateline2",     {  0.5, -179.5 }, { -0.5,  179.5 } },
	};
	NSUInteger boundsInfoCount = (sizeof(boundsInfoArray) / sizeof(REContainsLatLngBoundsInfo));

	REContainsTest testArray[] = {
		{ "Asia",          { 33.5,  140.0 }, YES },
		{ "Asia",          { 33.5,  141.1 }, NO  },
		{ "Asia",          { 33.5,  138.9 }, NO  },
		{ "NorthAmerica",  { 45.0,  -83.0 }, YES },
		{ "NorthAmerica",  { 45.5,  -84.0 }, NO  },
		{ "NorthAmerica",  { 45.5,  -82.0 }, NO  },
		{ "Dateline1",     { 10.0,  179.9 }, YES },
		{ "Dateline1",     { 10.0, -179.9 }, YES },
		{ "Dateline1",     { 10.0,  179.4 }, NO  },
		{ "Dateline1",     { 10.0, -179.4 }, NO  },
		{ "Dateline2",     {  0.0,  179.9 }, YES },
		{ "Dateline2",     {  0.0, -179.9 }, YES },
		{ "Dateline2",     {  0.6,  179.9 }, NO  },
		{ "Dateline2",     { -0.6,  179.9 }, NO  },
	};
	NSUInteger testCount = (sizeof(testArray) / sizeof(REContainsTest));

	for (unsigned long i = 0; i < testCount; ++i) {
		REContainsTest *test = &testArray[i];

		// Find boundsInfo element for this test case.
		REContainsLatLngBoundsInfo *boundsInfo = NULL;
		for (unsigned long j = 0; j < boundsInfoCount; ++j) {
			if (0 == strcmp(boundsInfoArray[j].tag, test->boundsTag)) {
				boundsInfo = &boundsInfoArray[j];
				break;
			}
		}

		if (!boundsInfo)
			NSLog(@"test %lu: Missing boundInfo for tag %s\n", i, test->boundsTag);
		else {
			RELatLngBounds *tmpLatLngBounds = [[RELatLngBounds alloc] initWithMapView:_mapView];
			[tmpLatLngBounds setSouthWest:boundsInfo->sw northEast:boundsInfo->ne];
			BOOL rv = [tmpLatLngBounds contains:test->coord];
			BOOL didPass = ((rv && test->isInBounds) || (!rv && !test->isInBounds));
			NSLog(@"test %lu: %@ (%s)\n", i, (didPass) ? @"OK" : @"FAIL", test->boundsTag);
		}
	}
}
#endif

@end
