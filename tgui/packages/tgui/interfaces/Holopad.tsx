import { BooleanLike } from '../../common/react';
import { useBackend } from '../backend';
import { Button, Section } from '../components';
import { Window } from '../layouts';

export type HolopadData = {
  holopad_list: Pad[];
  command_auth: BooleanLike;
  forcing_call: BooleanLike;
  call_range: number;
};

type Pad = {
  id: string;
  busy: BooleanLike;
  ref: string;
};

export const Holopad = (props, context) => {
  const { act, data } = useBackend<HolopadData>(context);

  return (
    <Window resizable>
      <Window.Content scrollable>
        <Section
          title="Selection Disc"
          buttons={
            <>
              <Button
                content="Summon AI"
                icon="chevron-circle-down"
                onClick={() => act('call_ai')}
              />
              {data.command_auth ? (
                <Button
                  content="Force Call"
                  tooltip="This is only available due to your command authorisation."
                  selected={data.forcing_call}
                  icon="microphone"
                  onClick={() => act('microphone')}
                />
              ) : (
                ''
              )}
            </>
          }>
          {data.holopad_list.length ? (
            <HolopadList />
          ) : (
            `No holopads found in your range of ${data.call_range} clicks.`
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};

export const HolopadList = (props, context) => {
  const { act, data } = useBackend<HolopadData>(context);

  return (
    <Section>
      {data.holopad_list.map((holopad) => (
        <Button
          key={holopad.id}
          content={holopad.id}
          disabled={holopad.busy}
          tooltip={holopad.busy && 'This holopad is busy.'}
          onClick={() => act('call_holopad', { call_holopad: holopad.ref })}
        />
      ))}
    </Section>
  );
};
