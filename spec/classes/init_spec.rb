require 'spec_helper'

describe 'irqbalance' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts.merge({ 'processors' => { 'count' => 2 } }) }

      it { is_expected.to compile }
    end
  end

  context 'without parameters' do
    let(:facts) do
      {
        'path' => '/bin:/usr/bin',
        'processors' => { 'count' => 2 },
      }
    end

    it { is_expected.to compile.with_all_deps }
    it {
      is_expected.to contain_package('irqbalance')
        .with_ensure('installed')
        .that_notifies('Service[irqbalance.service]')
    }

    it {
      is_expected.to contain_systemd__manage_dropin('puppet-oneshot.conf')
        .with_ensure('absent')
    }
    it {
      is_expected.to contain_systemd__manage_dropin('puppet.conf')
        .with_ensure('present')
        .with_unit('irqbalance.service')
        .with_service_entry({
                              'EnvironmentFile' => '/etc/sysconfig/irqbalance',
                              'ExecStart' => [
                                '',
                                '/usr/sbin/irqbalance --foreground $IRQBALANCE_ARGS',
                              ]
                            })
    }

    it {
      is_expected.to contain_service('irqbalance.service')
        .with_ensure('running')
        .with_enable(true)
    }

    it {
      is_expected.to contain_file('/etc/sysconfig/irqbalance')
        .with_ensure('file')
        .with_owner('root')
        .with_group('root')
        .with_mode('0644')
        .that_notifies('Service[irqbalance.service]')
        .with_content(%r{^#IRQBALANCE_BANNED_CPULIST=""})
        .with_content(%r{^IRQBALANCE_ARGS="-j"})
    }
  end

  context 'when given values for params used in /etc/sysconfig/irqbalance' do
    let(:facts) do
      {
        'path' => '/bin:/usr/bin',
        'processors' => { 'count' => 2 },
      }
    end

    let(:params) do
      {
        'oneshot'      => true,
        'powerthresh'  => 389,
        'ban_irq'      => [3, 7],
        'ban_mod'      => ['a', 'b'],
        'ban_cpu_list' => ['0', '0-11'],
        'deepestcache' => 3,
        'policyscript' => '/usr/bin/foo.sh',
        'migrateval'   => 4,
        'interval'     => 5,
        'extra_args'   => ['--beep', '--boop'],
      }
    end

    it {
      is_expected.to contain_file('/etc/sysconfig/irqbalance')
        .with_content(%r{^IRQBALANCE_BANNED_CPULIST="0,0-11"})
        .with_content(%r{^IRQBALANCE_ARGS="--oneshot --powerthresh=389 --deepestcache=3 --policyscript=/usr/bin/foo.sh --migrateval=4 --interval=5 --banirq=3 --banirq=7 --banmod=a --banmod=b --beep --boop"}) # rubocop:disable Layout/LineLength
    } # rubocop:enable Layout/LineLength
  end

  context 'when given values for params used in /etc/systemd/system/irqbalance.service.d/puppet.conf' do
    let(:facts) do
      {
        'path' => '/bin:/usr/bin',
        'processors' => { 'count' => 2 },
      }
    end

    let(:params) do
      {
        'oneshot' => true,
      }
    end

    it {
      is_expected.to contain_systemd__manage_dropin('puppet.conf')
        .with_ensure('present')
        .with_unit('irqbalance.service')
    }
    it {
      is_expected.to contain_systemd__manage_dropin('puppet-oneshot.conf')
        .with_ensure('present')
        .with_unit('irqbalance.service')
        .with_service_entry({
                              'Type' => 'oneshot',
                              'RemainAfterExit' => true,
                            })
    }
    it {
      is_expected.to contain_file('/etc/sysconfig/irqbalance')
        .with_ensure('file')
        .with_owner('root')
        .with_group('root')
        .with_mode('0644')
        .that_notifies('Service[irqbalance.service]')
        .with_content(%r{IRQBALANCE_ARGS="--oneshot -j"})
    }
  end

  context 'without enough CPU cores' do
    let(:facts) do
      {
        'path' => '/bin:/usr/bin',
        'processors' => { 'count' => 1 },
      }
    end

    let(:params) do
      {
        'service_ensure' => 'running',
        'service_enable' => true,
      }
    end

    it { is_expected.to compile.with_all_deps }
    it {
      is_expected.to contain_service('irqbalance.service')
        .with_ensure('stopped')
        .with_enable(false)
    }
  end
end
