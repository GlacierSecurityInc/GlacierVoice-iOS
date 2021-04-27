/*
 * Copyright (c) 2010-2019 Belledonne Communications SARL.
 *
 * This file is part of linphone-iphone
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#import "CallSideMenuView.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"

@implementation CallSideMenuView {
	NSTimer *updateTimer;
    
    NSDictionary *attrs;
    NSDictionary *boldTitleAttrs;
    NSDictionary *boldAttrs;
}

#pragma mark - ViewController Functions

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if (updateTimer != nil) {
		[updateTimer invalidate];
	}
	updateTimer = [NSTimer scheduledTimerWithTimeInterval:1
												   target:self
												 selector:@selector(updateStats:)
												 userInfo:nil
												  repeats:YES];

	[self updateStats:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	if (updateTimer != nil) {
		[updateTimer invalidate];
		updateTimer = nil;
	}
}

- (IBAction)onLateralSwipe:(id)sender {
	[PhoneMainView.instance.mainViewController hideSideMenu:YES];
}

+ (NSString *)iceToString:(LinphoneIceState)state {
	switch (state) {
		case LinphoneIceStateNotActivated:
			return NSLocalizedString(@"Not activated", @"ICE has not been activated for this call");
			break;
		case LinphoneIceStateFailed:
			return NSLocalizedString(@"Failed", @"ICE processing has failed");
			break;
		case LinphoneIceStateInProgress:
			return NSLocalizedString(@"In progress", @"ICE process is in progress");
			break;
		case LinphoneIceStateHostConnection:
			return NSLocalizedString(@"Direct connection",
									 @"ICE has established a direct connection to the remote host");
			break;
		case LinphoneIceStateReflexiveConnection:
			return NSLocalizedString(
				@"NAT(s) connection",
				@"ICE has established a connection to the remote host through one or several NATs");
			break;
		case LinphoneIceStateRelayConnection:
			return NSLocalizedString(@"Relay connection", @"ICE has established a connection through a relay");
			break;
	}
}

+ (NSString*)afinetToString:(int)remote_family {
	return (remote_family == LinphoneAddressFamilyUnspec) ? @"Unspecified":(remote_family == LinphoneAddressFamilyInet) ? @"IPv4" : @"IPv6";
}

+ (NSString *)mediaEncryptionToString:(LinphoneMediaEncryption)enc {
	switch (enc) {
		case LinphoneMediaEncryptionDTLS:
			return @"DTLS";
		case LinphoneMediaEncryptionSRTP:
			return @"SRTP";
		case LinphoneMediaEncryptionZRTP:
			return @"ZRTP";
		case LinphoneMediaEncryptionNone:
			break;
	}
	return NSLocalizedString(@"None", nil);
}

- (NSMutableAttributedString *)updateStatsForCall:(LinphoneCall *)call stream:(LinphoneStreamType)stream {
	NSMutableString *result = [[NSMutableString alloc] init];
	const PayloadType *payload = NULL;
	const LinphoneCallStats *stats;
	const LinphoneCallParams *params = linphone_call_get_current_params(call);
	NSString *name;

	switch (stream) {
		case LinphoneStreamTypeAudio:
			name = @"Audio";
			payload = linphone_call_params_get_used_audio_codec(params);
			stats = linphone_call_get_audio_stats(call);
			break;
		case LinphoneStreamTypeText:
			name = @"Text";
			payload = linphone_call_params_get_used_text_codec(params);
			stats = linphone_call_get_text_stats(call);
			break;
		case LinphoneStreamTypeVideo:
			name = @"Video";
			payload = linphone_call_params_get_used_video_codec(params);
			stats = linphone_call_get_video_stats(call);
			break;
		case LinphoneStreamTypeUnknown:
			break;
	}
    
    NSMutableAttributedString *aresult = [[NSMutableAttributedString alloc] initWithString:result
                                                                                attributes:attrs];
    
    if (payload == NULL) {
        return aresult;
    }
    
    NSMutableAttributedString *aname = [[NSMutableAttributedString alloc] initWithString:name
                                                                                        attributes:boldTitleAttrs];
    [aresult appendAttributedString:aname];
    
    NSMutableAttributedString *acodec = [[NSMutableAttributedString alloc] initWithString:@"\nCodec"
                                                                              attributes:boldAttrs];
    [aresult appendAttributedString:acodec];
    NSMutableAttributedString *acodecval = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@": %s/%iHz", payload->mime_type, payload->clock_rate] attributes:attrs];
    [aresult appendAttributedString:acodecval];
    
    if (stream == LinphoneStreamTypeAudio) {
        NSMutableAttributedString *achanval = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"/%i channels", payload->channels] attributes:attrs];
        [aresult appendAttributedString:achanval];
    }
    
    const char *enc_desc = ms_factory_get_encoder(linphone_core_get_ms_factory(LC), payload->mime_type)->text;
    const char *dec_desc = ms_factory_get_decoder(linphone_core_get_ms_factory(LC), payload->mime_type)->text;
    if (strcmp(enc_desc, dec_desc) == 0) {
        NSMutableAttributedString *acoder = [[NSMutableAttributedString alloc] initWithString:@"\nEncoder/Decoder"
                                                                                   attributes:boldAttrs];
        [aresult appendAttributedString:acoder];
        NSMutableAttributedString *acoderval = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@": %s", enc_desc] attributes:attrs];
        [aresult appendAttributedString:acoderval];
    } else {
        NSMutableAttributedString *aencoder = [[NSMutableAttributedString alloc] initWithString:@"\nEncoder"
                                                                                   attributes:boldAttrs];
        [aresult appendAttributedString:aencoder];
        NSMutableAttributedString *aencoderval = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@": %s", enc_desc] attributes:attrs];
        [aresult appendAttributedString:aencoderval];
        
        NSMutableAttributedString *adecoder = [[NSMutableAttributedString alloc] initWithString:@"\nDecoder"
                                                                                     attributes:boldAttrs];
        [aresult appendAttributedString:adecoder];
        NSMutableAttributedString *adecoderval = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@": %s", dec_desc] attributes:attrs];
        [aresult appendAttributedString:adecoderval];
    }
    
    if (stats != NULL) {
        NSMutableAttributedString *adownband = [[NSMutableAttributedString alloc] initWithString:@"\nDownload bandwidth" attributes:boldAttrs];
        [aresult appendAttributedString:adownband];
        NSMutableAttributedString *adownbandval = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@": %1.1f kbits/s", linphone_call_stats_get_download_bandwidth(stats)] attributes:attrs];
        [aresult appendAttributedString:adownbandval];
        
        NSMutableAttributedString *aupband = [[NSMutableAttributedString alloc] initWithString:@"\nUpload bandwidth" attributes:boldAttrs];
        [aresult appendAttributedString:aupband];
        NSMutableAttributedString *aupbandval = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@": %1.1f kbits/s", linphone_call_stats_get_upload_bandwidth(stats)] attributes:attrs];
        [aresult appendAttributedString:aupbandval];
        
        if (stream == LinphoneStreamTypeVideo) {
            NSMutableAttributedString *aestband = [[NSMutableAttributedString alloc] initWithString:@"\nEstimated download bandwidth" attributes:boldAttrs];
            [aresult appendAttributedString:aestband];
            NSMutableAttributedString *aestbandval = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@": %1.1f kbits/s", linphone_call_stats_get_estimated_download_bandwidth(stats)] attributes:attrs];
            [aresult appendAttributedString:aestbandval];
        }
        
        NSMutableAttributedString *aice = [[NSMutableAttributedString alloc] initWithString:@"\nICE state" attributes:boldAttrs];
        [aresult appendAttributedString:aice];
        NSMutableAttributedString *aiceval = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@": %@", [self.class iceToString:linphone_call_stats_get_ice_state(stats)]] attributes:attrs];
        [aresult appendAttributedString:aiceval];
        
        NSMutableAttributedString *ainet = [[NSMutableAttributedString alloc] initWithString:@"\nIP Family" attributes:boldAttrs];
        [aresult appendAttributedString:ainet];
        NSMutableAttributedString *ainetval = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@": %@", [self.class afinetToString:linphone_call_stats_get_ip_family_of_remote(stats)]] attributes:attrs];
        [aresult appendAttributedString:ainetval];
        
        // RTP stats section (packet loss count, etc)
        const rtp_stats_t rtp_stats = *linphone_call_stats_get_rtp_stats(stats);
        NSMutableAttributedString *artp = [[NSMutableAttributedString alloc] initWithString:@"\nRTP packets" attributes:boldAttrs];
        [aresult appendAttributedString:artp];
        NSMutableAttributedString *artpval = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@": %llu total, %lld cum loss, %llu discarded, %llu OOT, %llu bad", rtp_stats.packet_recv, rtp_stats.cum_packet_loss, rtp_stats.discarded,                  rtp_stats.outoftime, rtp_stats.bad] attributes:attrs];
        [aresult appendAttributedString:artpval];
        
        NSMutableAttributedString *asend = [[NSMutableAttributedString alloc] initWithString:@"\nSender loss rate" attributes:boldAttrs];
        [aresult appendAttributedString:asend];
        NSMutableAttributedString *asendval = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@": %.2f%%", linphone_call_stats_get_sender_loss_rate(stats)] attributes:attrs];
        [aresult appendAttributedString:asendval];
        
        NSMutableAttributedString *arcv = [[NSMutableAttributedString alloc] initWithString:@"\nReceiver loss rate" attributes:boldAttrs];
        [aresult appendAttributedString:arcv];
        NSMutableAttributedString *arcvval = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@": %.2f%%", linphone_call_stats_get_receiver_loss_rate(stats)] attributes:attrs];
        [aresult appendAttributedString:arcvval];
        
        NSMutableAttributedString *ajit = [[NSMutableAttributedString alloc] initWithString:@"\nJitter Buffer" attributes:boldAttrs];
        [aresult appendAttributedString:ajit];
        NSMutableAttributedString *ajitval = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@": %1.2f ms", linphone_call_stats_get_jitter_buffer_size_ms(stats)] attributes:attrs];
        [aresult appendAttributedString:ajitval];
        
        if (stream == LinphoneStreamTypeVideo) {
            MSVideoSize sentSize = linphone_call_params_get_sent_video_size(params);
            MSVideoSize recvSize = linphone_call_params_get_received_video_size(params);
            float sentFPS = linphone_call_params_get_sent_framerate(params);
            float recvFPS = linphone_call_params_get_received_framerate(params);
            
            NSMutableAttributedString *asendvid = [[NSMutableAttributedString alloc] initWithString:@"\nSent video resolution" attributes:boldAttrs];
            [aresult appendAttributedString:asendvid];
            NSMutableAttributedString *asendvidval = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@": %dx%d (%.1fFPS)", sentSize.width, sentSize.height, sentFPS] attributes:attrs];
            [aresult appendAttributedString:asendvidval];
            
            NSMutableAttributedString *arcvvid = [[NSMutableAttributedString alloc] initWithString:@"\nReceived video resolution" attributes:boldAttrs];
            [aresult appendAttributedString:arcvvid];
            NSMutableAttributedString *arcvvidval = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@": %dx%d (%.1fFPS)", recvSize.width, recvSize.height, recvFPS] attributes:attrs];
            [aresult appendAttributedString:arcvvidval];
        }
    }
    
	/*if (payload == NULL) {
		return result;
	}

	[result appendString:@"\n"];
	[result appendString:name];
	[result appendString:@"\n"];

	[result appendString:[NSString stringWithFormat:@"Codec: %s/%iHz", payload->mime_type, payload->clock_rate]];
	if (stream == LinphoneStreamTypeAudio) {
		[result appendString:[NSString stringWithFormat:@"/%i channels", payload->channels]];
	}
	[result appendString:@"\n"];
	// Encoder & decoder descriptions
	const char *enc_desc = ms_factory_get_encoder(linphone_core_get_ms_factory(LC), payload->mime_type)->text;
	const char *dec_desc = ms_factory_get_decoder(linphone_core_get_ms_factory(LC), payload->mime_type)->text;
	if (strcmp(enc_desc, dec_desc) == 0) {
		[result appendString:[NSString stringWithFormat:@"Encoder/Decoder: %s", enc_desc]];
		[result appendString:@"\n"];
	} else {
		[result appendString:[NSString stringWithFormat:@"Encoder: %s", enc_desc]];
		[result appendString:@"\n"];
		[result appendString:[NSString stringWithFormat:@"Decoder: %s", dec_desc]];
		[result appendString:@"\n"];
	}

	if (stats != NULL) {
		[result appendString:[NSString stringWithFormat:@"Download bandwidth: %1.1f kbits/s",
														linphone_call_stats_get_download_bandwidth(stats)]];
		[result appendString:@"\n"];
		[result appendString:[NSString stringWithFormat:@"Upload bandwidth: %1.1f kbits/s",
														linphone_call_stats_get_upload_bandwidth(stats)]];
		[result appendString:@"\n"];
        if (stream == LinphoneStreamTypeVideo) {
            [result appendString:[NSString stringWithFormat:@"Estimated download bandwidth: %1.1f kbits/s",
                                  linphone_call_stats_get_estimated_download_bandwidth(stats)]];
            [result appendString:@"\n"];
        }
		[result
			appendString:[NSString stringWithFormat:@"ICE state: %@",
													[self.class iceToString:linphone_call_stats_get_ice_state(stats)]]];
		[result appendString:@"\n"];
		[result
			appendString:[NSString
							 stringWithFormat:@"Afinet: %@",
											  [self.class afinetToString:linphone_call_stats_get_ip_family_of_remote(
																			 stats)]]];
		[result appendString:@"\n"];

		// RTP stats section (packet loss count, etc)
		const rtp_stats_t rtp_stats = *linphone_call_stats_get_rtp_stats(stats);
		[result
			appendString:[NSString stringWithFormat:
									   @"RTP packets: %llu total, %lld cum loss, %llu discarded, %llu OOT, %llu bad",
									   rtp_stats.packet_recv, rtp_stats.cum_packet_loss, rtp_stats.discarded,
									   rtp_stats.outoftime, rtp_stats.bad]];
		[result appendString:@"\n"];
		[result appendString:[NSString stringWithFormat:@"Sender loss rate: %.2f%%",
														linphone_call_stats_get_sender_loss_rate(stats)]];
		[result appendString:@"\n"];
		[result appendString:[NSString stringWithFormat:@"Receiver loss rate: %.2f%%",
														linphone_call_stats_get_receiver_loss_rate(stats)]];
		[result appendString:@"\n"];

		if (stream == LinphoneStreamTypeVideo) {
			const LinphoneVideoDefinition *recv_definition = linphone_call_params_get_received_video_definition(params);
			const LinphoneVideoDefinition *sent_definition = linphone_call_params_get_sent_video_definition(params);
			float sentFPS = linphone_call_params_get_sent_framerate(params);
			float recvFPS = linphone_call_params_get_received_framerate(params);
			[result appendString:[NSString stringWithFormat:@"Sent video resolution: %dx%d (%.1fFPS)", linphone_video_definition_get_width(sent_definition),
															linphone_video_definition_get_height(sent_definition), sentFPS]];
			[result appendString:@"\n"];
			[result appendString:[NSString stringWithFormat:@"Received video resolution: %dx%d (%.1fFPS)",
								  linphone_video_definition_get_width(recv_definition),
								  linphone_video_definition_get_height(recv_definition), recvFPS]];
			[result appendString:@"\n"];
		}
	}*/
	return aresult;
}

- (void)updateStats:(NSTimer *)timer {
	LinphoneCall *call = linphone_core_get_current_call(LC);

	if (!call) {
		_statsLabel.text = NSLocalizedString(@"No call in progress", nil);
		return;
	}

	NSMutableString *stats = [[NSMutableString alloc] init];
    
    const CGFloat fontSize = 16;
    if (!attrs) {
        attrs = @{ NSFontAttributeName:[UIFont systemFontOfSize:fontSize],
                   NSForegroundColorAttributeName:[UIColor blackColor] };
        boldTitleAttrs = @{ NSFontAttributeName:[UIFont boldSystemFontOfSize:fontSize+6],
                            NSForegroundColorAttributeName:[UIColor blackColor] };
        boldAttrs = @{ NSFontAttributeName:[UIFont boldSystemFontOfSize:fontSize],
                            NSForegroundColorAttributeName:[UIColor blackColor] };
    }
    
    NSDictionary *attrs = @{ NSFontAttributeName:[UIFont systemFontOfSize:fontSize],
                             NSForegroundColorAttributeName:[UIColor blackColor] };
    
    NSMutableAttributedString *attributedStats = [[NSMutableAttributedString alloc] initWithString:stats
                                                                                       attributes:attrs];
    [attributedStats appendAttributedString:[self updateStatsForCall:call stream:LinphoneStreamTypeAudio]];
    [attributedStats appendAttributedString:[self updateStatsForCall:call stream:LinphoneStreamTypeVideo]];
    [attributedStats appendAttributedString:[self updateStatsForCall:call stream:LinphoneStreamTypeText]];
    

    LinphoneMediaEncryption enc = linphone_call_params_get_media_encryption(linphone_call_get_current_params(call));
    if (enc != LinphoneMediaEncryptionNone) {
        
        [attributedStats appendAttributedString: [[NSAttributedString alloc] initWithString: [NSString
                stringWithFormat:@"\n\nCall encrypted using %@", [self.class mediaEncryptionToString:enc]]]];
    }
    
    [_statsLabel setAttributedText:attributedStats];
}

@end
