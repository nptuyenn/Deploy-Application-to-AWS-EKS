import { useCallback, useState } from 'react';
import * as React from 'react';
interface ChildProps {
  onClick: () => void;
}

const Child = React.memo(({ onClick }: ChildProps) => {
  console.log("Child render");
  return <button onClick={onClick}>Click Child</button>;
});

function ComponentTest() {
  const [count, setCount] = useState(0);

  const handleClick = useCallback(() => {
    console.log("Clicked");
  }, []); // không đổi => Child không re-render
  ////////////////////////////////
  return (
    <div>
      <h2>Count: {count}</h2>
      <button onClick={() => setCount(count + 1)}>Tăng</button>
      <Child onClick={handleClick} />
    </div>
  );
}
export default ComponentTest;