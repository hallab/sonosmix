from kivy.app import App
from kivy.uix.widget import Widget
from kivy.uix.boxlayout import BoxLayout
from kivy.properties import StringProperty, ListProperty
from soco import SoCo, SonosDiscovery
from threading import Thread, Event
from time import sleep
from kivy.clock import Clock
from kivy.uix.slider import Slider
from kivy.uix.popup import Popup

class VolumeSlider(Slider):
    def on_touch_down(self, touch):
        tx, ty = touch.pos 
        vx, vy = self.value_pos
        if touch.is_mouse_scrolling or (abs(ty - vy) < 32 and abs(tx - self.center_x) < 32):
            return Slider.on_touch_down(self, touch)

class SonosMixer(BoxLayout):
    speakers = ListProperty()

    def __init__(self, **kwargs):
        BoxLayout.__init__(self, **kwargs)
        self.bind(speakers=self.update_speakers)

    def update_speakers(self, *args):
        self.ids.mixer.clear_widgets()
        for sonos in self.speakers:
            self.ids.mixer.add_widget(SpeakerCtrl(sonos))

class SpeakerCtrl(BoxLayout):
    name = StringProperty()

    def __init__(self, sonos, **kwargs):
        BoxLayout.__init__(self, **kwargs)
        self.sonos = sonos
        self.name = sonos.name
        self.ids.volume_slider.value = self.sonos.volume()
        self.ids.volume_slider.bind(value=self.update_volume)

    def update_volume(self, *args):
        self.sonos.volume(self.ids.volume_slider.value)

class InfoPopup(Popup):
    def view(self, url):
        from android import open_url
        open_url(url)

class SonosMixerApp(App):
    def build(self):
        self.root = SonosMixer()
        self.discoverer = AssyncDiscoverer(self.speakers_discovered)
        self.discoverer.start()
        self.popup = None
        return self.root

    def speakers_discovered(self, speakers):
        self.root.speakers = speakers

    def on_pause(self):
        self.discoverer.interrupted = True
        return True

    def on_resume(self):
        self.discoverer.interrupted = True

    def open_settings(self, *args):
        if self.popup:
            self.popup.dismiss()
        self.popup = InfoPopup()
        self.popup.open()


class AssyncDiscoverer(Thread):
    daemon = True
    def __init__(self, callback):
        Thread.__init__(self)
        self.callback = callback

    def run(self):
        discover = SonosDiscovery()
        speakers = []
        prev_found = []
        prev_known = set()
        def call_callback(*args):
            self.callback(speakers)
        while True:
            self.interrupted = False
            try:
                found = discover.get_speaker_ips()
            except Exception as e:
                print e
                sleep(60)
                continue
            known = set(prev_found + found)
            if known != prev_known:
                speakers = [SoCo(ip) for ip in known]
                for sonos in speakers:
                    sonos.name = sonos.get_speaker_info()['zone_name']
                speakers.sort(key=lambda o: o.name)
                if not self.interrupted:
                    Clock.schedule_once(call_callback)
                    sleep(60)
            else:
                sleep(60)
            prev_known = known
            prev_found = found

if __name__ == '__main__':
    SonosMixerApp().run()

