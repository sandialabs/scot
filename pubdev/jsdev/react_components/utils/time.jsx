import Moment from 'moment';
import { extendMoment } from 'moment-range';
const moment = extendMoment( Moment );

/**
 * Calculate if a timestamp is older than a number of seconds
 *
 * timestamp: Date() object to test against
 * secondsAgo: Number of seconds to test against
 */
export const timeOlderThan = ( timestamp, secondsAgo ) => {
    if ( !timestamp ) {
        return true;
    }

    return Date.now() - timestamp > ( secondsAgo * 1000 );
};

/**
 * Calculate if a timestamp is in the past and therefore data is expired
 *
 * expires: time data expires
 */
export const isExpired = ( expires ) => {
    return !expires || Date.now() >= expires;
};

/**
 * Conversion Functions for DateRangeFilter
 *
 * epochRangeToString: stringify an epoch range
 * epochRangeToMoment: convert epoch range into MomentRange object
 * momentRangeToEpoch: convert MomentRange object to epoch range
 *
 * epoch range: { start: _epoch_, end: _epoch_ }
 */
export const epochRangeToString = range => {
    return range.start +', '+ range.end;
};

export const epochRangeToMoment = range => {
    return moment.range( range.start * 1000, range.end * 1000 );
};

export const momentRangeToEpoch = range => {
    return {
        start: Math.round( range.start ) / 1000,
        end: Math.round( range.end ) / 1000,
    };
};
