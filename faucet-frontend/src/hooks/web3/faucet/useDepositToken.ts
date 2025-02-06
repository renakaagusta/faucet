import faucetABI from '@/abis/faucet/FaucetABI';
import ERC20ABI from '@/abis/tokens/ERC20ABI';
import { wagmiConfig } from '@/configs/wagmi';
import { FAUCET_ADDRESS } from '@/constants/contract-address';
import { HexAddress } from '@/types/web3/general/address';
import { useState, useEffect } from 'react';
import { toast } from 'sonner';
import { useSimulateContract, useWaitForTransactionReceipt, useWriteContract } from 'wagmi';
import { readContract, getAccount, getPublicClient } from '@wagmi/core';

export const useDepositToken = () => {
    const [allowance, setAllowance] = useState<bigint>(BigInt(0));

    const [isDepositAlertOpen, setIsDepositAlertOpen] = useState(false);
    const [approvalParams, setApprovalParams] = useState<{
        tokenAddress?: HexAddress,
        amount?: bigint
    }>();
    const [simulationParams, setSimulationParams] = useState<{
        tokenAddress?: HexAddress,
        amount?: bigint
    }>();

    // Simulation hook
    const {
        data: simulateData,
        isError: isDepositSimulationError,
        isLoading: isDepositSimulationLoading,
        refetch: refetchDepositSimulation,
        error: simulateError,
    } = useSimulateContract({
        address: FAUCET_ADDRESS as HexAddress,
        abi: faucetABI,
        functionName: 'depositToken',
        args: simulationParams?.tokenAddress ? [
            simulationParams.tokenAddress,
            simulationParams.amount
        ] : undefined,
    });

    // Deposit transaction hooks
    const {
        data: depositHash,
        isPending: isDepositPending,
        writeContract: writeDeposit
    } = useWriteContract();

    const {
        isLoading: isDepositConfirming,
        isSuccess: isDepositConfirmed
    } = useWaitForTransactionReceipt({
        hash: depositHash,
    });

    // Approval transaction hooks
    const {
        data: approvalHash,
        isPending: isApprovalPending,
        writeContract: writeApproval
    } = useWriteContract();

    const {
        isLoading: isApprovalConfirming,
        isSuccess: isApprovalConfirmed
    } = useWaitForTransactionReceipt({
        hash: approvalHash,
    });

    const handleApprovalDeposit = async (tokenAddress: HexAddress, amount: bigint) => {
        try {
            const allowanceResult = await readContract(wagmiConfig, {
                address: tokenAddress,
                abi: ERC20ABI,
                functionName: 'allowance',
                args: [getAccount(wagmiConfig).address, FAUCET_ADDRESS],
            });

            setAllowance(allowanceResult as bigint);
            setApprovalParams({
                tokenAddress,
                amount
            });

            if (Number(allowanceResult) < Number(amount)) {
                toast.info('Requesting approval');
                writeApproval({
                    address: tokenAddress,
                    abi: ERC20ABI,
                    functionName: 'approve',
                    args: [FAUCET_ADDRESS, amount],
                });
            } else {
                setSimulationParams({ tokenAddress, amount });
                setApprovalParams(undefined);
            }
        } catch (error) {            
            toast.error(error instanceof Error ? error.message : 'Approval failed. Please try again.');
        }
    };

    const handleDeposit = async () => {
        try {
            if (!approvalParams) {
                return;
            }

            const { tokenAddress, amount } = approvalParams;
            console.log('============ Deposit Parameters ============');
            console.log('Contract Details:');
            console.log(`Address: ${FAUCET_ADDRESS}`);
            console.log(`Function: deposit`);
            console.log('\nArguments:');
            console.log(`Token Address: ${tokenAddress}`);
            console.log(`Amount: ${amount}`);
            console.log('===============================================');

            setSimulationParams({ tokenAddress, amount });
            setApprovalParams(undefined);
        } catch (error) {
            console.error('Transaction error:', error);
            toast.error(error instanceof Error ? error.message : 'Transaction failed. Please try again.');
        }
    };

    // Effect for simulation
    useEffect(() => {
        console.log('============ Simulation ============');
        console.log(`simulationParams: ${simulationParams}`);
        console.log(`isDepositSimulationLoading: ${isDepositSimulationLoading}`);
        console.log('===============================================');

        if (!simulationParams || isDepositSimulationLoading) {
            return;
        }

        console.log('============ Simulation initializing  ============');        refetchDepositSimulation();
    }, [simulationParams, isDepositSimulationLoading]);

    // Effect for handling deposit after approval
    useEffect(() => {
        console.log('============ Deposit ============');
        console.log(`isApprovalConfirmed: ${isApprovalConfirmed}`);
        console.log(`approvalParams: ${approvalParams}`);
        console.log(`simulationParams: ${simulationParams}`);
        console.log(`allowance: ${allowance}`);
        console.log('===============================================');

        if ((!isApprovalConfirmed || !approvalParams) && (!simulationParams || allowance < (simulationParams?.amount ?? BigInt(0)))) {
            return;
        }

        handleDeposit();
    }, [isApprovalConfirmed, approvalParams, simulationParams, allowance]);

    // Effect for success message
    useEffect(() => {
        if (!isDepositConfirmed) {
            return;
        }
        toast.success('Token has been deposited');
        setIsDepositAlertOpen(true);
    }, [isDepositConfirmed]);

    // Effect for simulation errors
    useEffect(() => {
        if (!simulateError || !isDepositSimulationError || isDepositSimulationLoading) {
            return;
        }
        toast.error(simulateError.toString());
    }, [simulateError, isDepositSimulationError]);

    // Effect for executing transaction after successful simulation
    useEffect(() => {
        if (!simulateData || isDepositConfirming) {
            return;
        }
        writeDeposit(simulateData.request);
        setSimulationParams(undefined);
    }, [simulateData]);

    console.log('==== SIMULATION DATA ====');
    console.log(`simulateData: ${simulateData}`);
    console.log(`isDepositSimulationLoading: ${isDepositSimulationLoading}`);
    console.log(`isDepositSimulationError: ${isDepositSimulationError}`);
    console.log(`simulateError: ${simulateError}`);
    console.log('========================');

    return {
        isDepositAlertOpen,
        setIsDepositAlertOpen,
        depositHash,
        isDepositPending,
        isApprovalPending,
        isDepositConfirming,
        isApprovalConfirming,
        handleApprovalDeposit,
        isDepositConfirmed,
        isDepositSimulationError,
        isDepositSimulationLoading,
        simulateError
    };
};