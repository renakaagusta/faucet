'use client';

import ERC20ABI from "@/abis/tokens/ERC20ABI";
import { Button } from "@/components/button/button";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/form/form";
import { Label } from "@/components/label/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/select/select";
import SuccessDialog from "@/components/success-dialog/success-dialog";
import { DataTable } from "@/components/table/data-table";
import { requestTokenColumns } from "@/components/table/faucet/request-token/columns";
import ClientWrapper from "@/components/wrapper/client-wrapper";
import { wagmiConfig } from "@/configs/wagmi";
import { FAUCET_ADDRESS } from "@/constants/contract-address";
import { FAUCET_INDEXER_URL } from "@/constants/subgraph-url";
import { queryAddTokens, queryRequestTokens } from "@/graphql/faucet/faucet.query";
import { useDepositToken } from "@/hooks/web3/faucet/useDepositToken";
import { useBalance } from "@/hooks/web3/token/useBalance";
import { AddTokensData } from "@/types/web3/faucet/add-token";
import { RequestTokensData } from "@/types/web3/faucet/request-token";
import { HexAddress } from "@/types/web3/general/address";
import { Token } from "@/types/web3/tokens/token";

import { zodResolver } from "@hookform/resolvers/zod";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { useQuery } from "@tanstack/react-query";
import { readContract } from "@wagmi/core";
import { request } from 'graphql-request';
import { History, Wallet } from "lucide-react";
import type { NextPage } from "next";
import { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { formatUnits, parseUnits } from "viem";
import {
  useAccount
} from "wagmi";
import * as z from "zod";

const faucetSchema = z.object({
  token: z.string().min(1),
  amount: z.string().min(1),
});

const Home: NextPage = () => {
  const form = useForm<z.infer<typeof faucetSchema>>({
    resolver: zodResolver(faucetSchema),
    defaultValues: {
      token: "",
    },
  });
  const { watch } = form;
  const selectedTokenAddress = watch("token");

  const { address: userAddress, isConnected } = useAccount();

  const [availableTokens, setAvailableTokens] = useState<Record<string, Token>>({});

  const { balance: userBalance, error: userBalanceError } = useBalance(userAddress as HexAddress, selectedTokenAddress as HexAddress);
  const { balance: faucetBalance, error: faucetBalanceError } = useBalance(FAUCET_ADDRESS as HexAddress, selectedTokenAddress as HexAddress);

  const {
    handleApprovalDeposit,
    isDepositConfirming,
    depositHash,
    isDepositAlertOpen,
    setIsDepositAlertOpen,
  } = useDepositToken();

  const { data: addTokensData, isLoading: addTokensIsLoading, refetch: addTokensRefetch } = useQuery<AddTokensData>({
    queryKey: ['addTokensData'],
    queryFn: async () => {
      return await request(FAUCET_INDEXER_URL as string, queryAddTokens);
    },
    staleTime: Infinity,
    refetchOnWindowFocus: false,
    refetchOnMount: false,
    refetchOnReconnect: false,
    retry: false,
  });

  const { data: requestTokensData, isLoading: requestTokensIsLoading, refetch: requestTokensRefetch } = useQuery<RequestTokensData>({
    queryKey: ['requestTokensData'],
    queryFn: async () => {
      return await request(FAUCET_INDEXER_URL as string, queryRequestTokens);
    },
    staleTime: Infinity,
    refetchOnWindowFocus: false,
    refetchOnMount: false,
    refetchOnReconnect: false,
    retry: false,
  });


  const onSubmit = async (values: z.infer<typeof faucetSchema>) => {
    handleApprovalDeposit(selectedTokenAddress as HexAddress, BigInt(parseUnits(values.amount.toString(), 18)));
  };

  useEffect(() => {
    if (!addTokensData) {
      return;
    }

    const fetchTokensData = async () => {
      const availableTokens: Record<string, Token> = {}

      await Promise.all(addTokensData.addTokens.items.map(async (addTokenData) => {
        let tokenName = '';
        let tokenSymbol = '';

        try {
          const tokenNameResult = await readContract(wagmiConfig, {
            address: addTokenData.address,
            abi: ERC20ABI,
            functionName: 'name',
            args: [],
          });

          const tokenSymbolResult = await readContract(wagmiConfig, {
            address: addTokenData.address,
            abi: ERC20ABI,
            functionName: 'symbol',
            args: [],
          });

          tokenName = tokenNameResult as string;
          tokenSymbol = tokenSymbolResult as string;
        } catch (err: unknown) {
          console.log('Error fetching token name of', addTokenData.address, err);
        }

        availableTokens[addTokenData.address] = {
          address: addTokenData.address,
          name: tokenName,
          symbol: tokenSymbol,
        };
      }))

      setAvailableTokens(availableTokens);
    }

    fetchTokensData();
  }, [addTokensData])

  useEffect(() => {
    requestTokensRefetch();
  }, [])

  return (
    <main>
      <SuccessDialog
        open={isDepositAlertOpen}
        onOpenChange={setIsDepositAlertOpen}
        txHash={depositHash}
        isLoading={isDepositConfirming}
      />
      <ClientWrapper>
        <div>
          {isConnected && (
            <div className="mt-[5rem] rounded-lg p-4 flex flex-col justify-between w-full lg:w-[70vw]">
              <h1 className="text-4xl font-bold">Deposit</h1>
              <p className="text-lg text-gray-500 mt-2">
                Deposit tokens to our faucet
              </p>
              <Form {...form}>
                <form
                  onSubmit={form.handleSubmit(onSubmit)}
                  onError={(e) => {
                    console.log(e);
                  }}
                  className="mt-3 space-y-5"
                >
                  <FormField
                    control={form.control}
                    name="token"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Token</FormLabel>
                        <Select
                          onValueChange={field.onChange}
                          defaultValue={field.value}
                        >
                          <FormControl>
                            <SelectTrigger>
                              <SelectValue placeholder="Select token" />
                            </SelectTrigger>
                          </FormControl>
                          <SelectContent>
                            {Object.keys(availableTokens)?.map((key: string) => (
                              <SelectItem key={availableTokens[key].address} value={availableTokens[key].address}>
                                {availableTokens[key].name} - {availableTokens[key].symbol}
                              </SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={form.control}
                    name="amount"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Amount</FormLabel>
                        <FormControl>
                          <input
                            type="number"
                            className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
                            placeholder="Enter amount to deposit"
                            {...field}
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <div className="flex flex-row gap-4">
                    <div className="flex flex-row gap-2 bg-gray-600 bg-opacity-50 p-3 rounded-xl"><Wallet /> <Label className="text-md">Faucet balance: {faucetBalance ? `${formatUnits(BigInt(faucetBalance), 18)} ${availableTokens[selectedTokenAddress]?.symbol}` : '-'}</Label></div>
                    <div className="flex flex-row gap-2 bg-gray-600 bg-opacity-50 p-3 rounded-xl"><Wallet /> <Label className="text-md">Your balance: {userBalance ? `${formatUnits(BigInt(userBalance), 18)} ${availableTokens[selectedTokenAddress]?.symbol}` : '-'}</Label></div>
                  </div>
                  <Button variant="default" type="submit">
                    Deposit
                  </Button>
                </form>
              </Form>
              <div className="mt-[10rem] w-full space-y-4 h-auto z-10">
                <div className="flex flex-row gap-2"><History /> <h1 className="text-xl">History</h1></div>
                <DataTable
                  data={
                    requestTokensData?.requestTokens.items
                      ? requestTokensData.requestTokens.items
                      : []
                  }
                  columns={requestTokenColumns()}
                  handleRefresh={() => { }}
                  isLoading={requestTokensIsLoading}
                />
              </div>
            </div>
          )}
          {
            !isConnected && <div className="flex flex-col items-center gap-2">
              <h4 className="text-3xl text-center">Connect Wallet</h4>
              <p className="text-lg font-light mb-4">Please connect your wallet to use this service</p>
              <ConnectButton />
            </div>
          }
        </div>
      </ClientWrapper>
    </main>
  );
};

export default Home;
